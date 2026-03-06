"""Patch grottserver.py to fix upstream bugs."""

with open('/app/grottserver.py', 'r') as f:
    code = f.read()

# Strip trailing whitespace from every line first (source has inconsistent trailing spaces)
lines = code.split('\n')
code = '\n'.join(line.rstrip() for line in lines)

# =============================================================================
# Patch 1: Fix "cannot access local variable 'value'" when empty register
# response is received for rectype "05".
#
# The original code doesn't assign 'value' when the response is empty,
# but then falls through to commandresponse[rectype][regkey] = {"value": value}
# which crashes. Fix: initialize value = None and skip commandresponse update.
# =============================================================================

old_block1 = '            elif rectype in ("19","05","06","18"):\n' + \
             '                if verbose: print("\\t - Grottserver - " + header[12:16] + " Command Response record received, no response needed")\n' + \
             '\n' + \
             '                offset = 0'

new_block1 = '            elif rectype in ("19","05","06","18"):\n' + \
             '                if verbose: print("\\t - Grottserver - " + header[12:16] + " Command Response record received, no response needed")\n' + \
             '\n' + \
             '                value = None\n' + \
             '                offset = 0'

if old_block1 in code:
    code = code.replace(old_block1, new_block1, 1)
    print("Patch 1a applied: initialized value = None")
else:
    print("WARNING: Patch 1a target not found")

# Guard the commandresponse update for rectype 05/19 to skip when value is None
old_block2 = '''                else :
                    #rectype 05 or 19
                    commandresponse[rectype][regkey] = {"value" : value}'''

new_block2 = '                else :\n' + \
             '                    #rectype 05 or 19\n' + \
             '                    if value is not None:\n' + \
             '                        commandresponse[rectype][regkey] = {"value" : value}\n' + \
             '                    else:\n' + \
             '                        if verbose: print("\\t - Grottserver - skipping commandresponse update, no value received")'

if old_block2 in code:
    code = code.replace(old_block2, new_block2, 1)
    print("Patch 1b applied: guarded commandresponse update")
else:
    print("WARNING: Patch 1b target not found")

# =============================================================================
# Patch 2: Fix UTF-8 decode errors on binary data.
#
# The loggerid decode uses .decode('utf-8') which crashes on non-UTF-8 bytes.
# Fix: use errors='replace' to handle invalid bytes gracefully.
# =============================================================================

old_decode = "loggerid = codecs.decode(loggerid, \"hex\").decode('utf-8')"
new_decode = "loggerid = codecs.decode(loggerid, \"hex\").decode('utf-8', errors='replace')"

count = code.count(old_decode)
if count > 0:
    code = code.replace(old_decode, new_decode)
    print(f"Patch 2 applied: fixed {count} UTF-8 decode(s) with errors='replace'")
else:
    print("WARNING: Patch 2 target not found")

# =============================================================================
# Patch 3: Fix the if/elif chain bug for rectype "18".
#
# Original code has:
#   if rectype == "06": ...
#   if rectype == "18": ...    <-- should be elif
#   else: ...
#
# This means for rectype "06", it also hits the else branch and tries to use
# 'value' again (double-writes). For rectype "05"/"19", it correctly hits else.
# Fix: change second 'if' to 'elif'.
# =============================================================================

old_chain = '''                    commandresponse["05"][regkey] = {"value" : value}
                if rectype == "18" :'''

new_chain = '''                    commandresponse["05"][regkey] = {"value" : value}
                elif rectype == "18" :'''

if old_chain in code:
    code = code.replace(old_chain, new_chain, 1)
    print("Patch 3 applied: fixed if/elif chain for rectype 18")
else:
    print("WARNING: Patch 3 target not found")

# =============================================================================
# Patch 4: Make verbose configurable via GROTTSERVER_VERBOSE environment variable.
#
# grottserver.py hardcodes verbose = True and ignores grott.ini.
# Replace with env var check so the addon can control it.
# =============================================================================

old_verbose = 'verbose = True'
new_verbose = 'import os\nverbose = os.environ.get("GROTTSERVER_VERBOSE", "false").lower() == "true"'

if old_verbose in code:
    code = code.replace(old_verbose, new_verbose, 1)
    print("Patch 4 applied: verbose now reads from GROTTSERVER_VERBOSE env var")
else:
    print("WARNING: Patch 4 target not found")

# =============================================================================
# Patch 5: Guard remaining unconditional high-frequency prints with 'if verbose:'.
#
# Even with verbose=False, some prints fire on every record.
# =============================================================================

noise_patches = [
    # decrypt() prints on every single record decryption
    (
        '    print("\\t - " + "Grott - data decrypted V2")',
        '    if verbose: print("\\t - " + "Grott - data decrypted V2")',
    ),
    # process_data prints on every incoming data record
    (
        '            print(f"\\t - Grottserver - Data received from : {client_address}:{client_port}")',
        '            if verbose: print(f"\\t - Grottserver - Data received from : {client_address}:{client_port}")',
    ),
    # data record type print on every 03/04/50/1b/20 record
    (
        '                print("\\t - Grottserver - " + header[12:16] + " data record received")',
        '                if verbose: print("\\t - Grottserver - " + header[12:16] + " data record received")',
    ),
    # queue response print (in process_data)
    (
        '                print("\\t - Grottserver - Put response on queue: ", qname, " msg: ")',
        '                if verbose: print("\\t - Grottserver - Put response on queue: ", qname, " msg: ")',
    ),
]

patch5_count = 0
for old, new in noise_patches:
    if old in code:
        code = code.replace(old, new)
        patch5_count += 1

if patch5_count > 0:
    print(f"Patch 5 applied: guarded {patch5_count} noisy prints behind verbose check")
else:
    print("WARNING: Patch 5 - no noise targets found")

with open('/app/grottserver.py', 'w') as f:
    f.write(code)

print("All patches complete.")
