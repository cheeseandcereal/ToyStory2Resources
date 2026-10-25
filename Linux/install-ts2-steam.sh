#!/usr/bin/env bash
set -euo pipefail
umask 077

stage=
FIX_DEFAULT_URL=https://github.com/cheeseandcereal/ToyStory2Fix/releases/latest/download/ToyStory2Fix.zip
D7VK_DEFAULT_URL=https://github.com/WinterSnowfall/d7vk/releases/download/v2.3/d7vk-v2.3.zip

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: bash ${0##*/} ISO [OPTIONS]

Install Toy Story 2 from a PC ISO with ToyStory2Fix and D7VK, and add it to Steam.

Options:
      --install-dir DIR Install into an absent or empty directory
                         Default: ${XDG_DATA_HOME:-$HOME/.local/share}/toy-story-2
  -f, --fix URL_OR_ZIP   Local ToyStory2Fix ZIP or HTTP(S) URL
                         Default: $FIX_DEFAULT_URL
  -i, --fix-ini FILE     Copy FILE unchanged as ToyStory2Fix.ini
  -d, --d7vk URL_OR_ZIP  Local D7VK release ZIP or HTTP(S) URL
                         Default: $D7VK_DEFAULT_URL
  -h, --help             Show this help
EOF
}

cleanup() {
    if [[ -n $stage ]]; then
        find "$stage" -type d -exec chmod u+rwx -- {} \; 2>/dev/null || :
        rm -rf -- "$stage"
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

extract() {
    local archive=$1 output=$2
    shift 2
    if [[ ${extractor##*/} == bsdtar ]]; then
        "$extractor" -xf "$archive" -C "$output" --no-same-owner --no-same-permissions \
            --no-acls --no-xattrs --no-fflags -- "$@"
    else
        "$extractor" x -y -o"$output" -- "$archive" "$@"
    fi
}

fetch_archive() {
    local source=$1 output=$2
    case $source in
        http://*|https://*)
            curl --fail --location --show-error --proto '=http,https' --proto-redir '=http,https' \
                --output "$output" "$source"
            ;;
        *) cp -- "$source" "$output" ;;
    esac
}

configure_loader() {
    # DxWrapper's exit-time resolution reset hangs in Wine window cleanup.
    awk -v ORS='\r\n' '
        tolower($0) ~ /^[[:space:]]*resetscreenres[[:space:]]*=/ { next }
        { sub(/\r$/, ""); print }
        tolower($0) ~ /^[[:space:]]*\[[[:space:]]*compatibility[[:space:]]*\]/ {
            print "ResetScreenRes=0"
            found = 1
        }
        END { if (!found) print "[Compatibility]\r\nResetScreenRes=0" }
    ' "$stage/game/dsound.ini" > "$stage/dsound.ini"
    mv -- "$stage/dsound.ini" "$stage/game/dsound.ini"
}

find_wscript() {
    local root vdf line library parent candidate
    local path_line='^[[:space:]]*"path"[[:space:]]*"(([^"\\]|\\.)*)"'
    local -a parents=()
    for root in "${XDG_DATA_HOME:-$HOME/.local/share}/Steam" "$HOME/.local/share/Steam" \
        "$HOME"/.steam/{root,steam,debian-installation}; do
        parents+=("$root"/{steamapps/common,compatibilitytools.d})
        for vdf in "$root"/{steamapps,config}/libraryfolders.vdf; do
            [[ -r $vdf ]] || continue
            while IFS= read -r line || [[ -n $line ]]; do
                [[ $line =~ $path_line ]] || continue
                library=${BASH_REMATCH[1]//\\\"/\"}
                library=${library//\\\\/\\}
                [[ $library != /* ]] || parents+=("$library"/{steamapps/common,compatibilitytools.d})
            done < "$vdf"
        done
    done
    parents+=(/usr/local/share/steam/compatibilitytools.d /usr/share/steam/compatibilitytools.d)
    # Identify Wine's builtin wscript.exe by Proton's installed layout.
    for parent in "${parents[@]}"; do
        for candidate in "$parent"/*/files/{lib,lib64}/wine/x86_64-windows/wscript.exe; do
            [[ -f $candidate && -r $candidate ]] || continue
            donor=$candidate
            return
        done
    done
    die 'No installed Proton with a readable Wine builtin wscript.exe found. Install Proton through native Steam first.'
}

desktop_string() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}
    value=${value// /\\s}
    printf '%s' "$value"
}

desktop_arg() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//\$/\\\$}
    value=${value//\`/\\\`}
    printf '"%s"' "$(desktop_string "$value")"
}

write_helpers() {
    install -m 700 -T -- "$donor" "$stage/game/wscript.exe"
    cat > "$stage/game/launch.vbs" <<'VBS'
Option Explicit
Const GameKey = "HKLM\Software\TravellersTalesToyStory2"
Const AppKey = "HKCU\Software\Wine\AppDefaults\toy2.exe"
Dim shell, folder, gameArgs, i
Set shell = CreateObject("WScript.Shell")
folder = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
shell.CurrentDirectory = folder
gameArgs = ""
For i = 0 To WScript.Arguments.Count - 1
    gameArgs = gameArgs & " " & Quote(WScript.Arguments(i))
Next

If shell.Run("reg.exe query " & GameKey & " /v path /reg:32", 0, True) <> 0 Then
    WriteRegistry AppKey & "\X11 Driver", "Managed", "Y"
    WriteRegistry AppKey & "\DllOverrides", "dsound", "native,builtin"
    WriteRegistry AppKey & "\DllOverrides", "ddraw", "native,builtin"
    WriteRegistry GameKey, "cdpath", folder & "\CD\"
    WriteRegistry GameKey, "path", folder & "\data\"
End If
WScript.Quit shell.Run("toy2.exe" & gameArgs, 1, True)

Function Quote(ByVal value)
    Dim escapes
    Set escapes = New RegExp
    escapes.Pattern = "[\s" & Chr(34) & "]"
    If Len(value) > 0 And Not escapes.Test(value) Then
        Quote = value
        Exit Function
    End If
    escapes.Global = True
    ' Double backslashes before quotes and at the end, then escape quotes.
    escapes.Pattern = "(\\+)(?=" & Chr(34) & "|$)"
    value = escapes.Replace(value, "$1$1")
    Quote = Chr(34) & Replace(value, Chr(34), "\" & Chr(34)) & Chr(34)
End Function

Sub WriteRegistry(key, name, value)
    Dim status
    status = shell.Run("reg.exe add " & Quote(key) & " /v " & name & _
        " /t REG_SZ /d " & Quote(value) & " /reg:32 /f", 0, True)
    If status <> 0 Then WScript.Quit status
End Sub
VBS
    {
        printf '[Desktop Entry]\nType=Application\nName=Toy Story 2\nTerminal=false\n'
        printf 'Exec=%s //B launch.vbs\n' "$(desktop_arg "$destination/wscript.exe")"
        printf 'Path=%s\n' "$(desktop_string "$destination")"
        if [[ -f $stage/game/toy2.ico ]]; then
            printf 'Icon=%s\n' "$(desktop_string "$destination/toy2.ico")"
        fi
    } > "$stage/game/steam.desktop"
}

url_encode() {
    local LC_ALL=C value=$1 char i
    for (( i=0; i<${#value}; i++ )); do
        char=${value:i:1}
        case $char in
            [a-zA-Z0-9.~_-]) printf '%s' "$char" ;;
            *) printf '%%%02X' "'$char" ;;
        esac
    done
}

register() {
    local directory=$1 marker=/tmp/addnonsteamgamefile
    command -v steam >/dev/null ||
        die "Steam command not found. Installation retained at $directory."
    if [[ -e $marker || -L $marker ]]; then
        [[ -f $marker && ! -L $marker && -O $marker ]] || die "Steam import marker must be a regular file owned by you: $marker"
    else
        (set -o noclobber; : > "$marker") || return 1
    fi
    nohup steam "steam://addnonsteamgame/$(url_encode "$directory/steam.desktop")" </dev/null >/dev/null 2>&1 &
    printf 'Steam import requested for %s. Check your steam library\n' "$directory"
}

main() {
    local iso destination fix=$FIX_DEFAULT_URL fix_ini= d7vk=$D7VK_DEFAULT_URL parent bad extractor
    local game_exe cd_dir icon
    local -a d7vk_dlls=()
    [[ $# -gt 0 ]] || { usage; exit 1; }
    case $1 in
        -h|--help) usage; return ;;
        -*) die "Unknown option: $1" ;;
    esac
    (( EUID != 0 )) || die 'Run as your normal desktop user, without sudo.'
    [[ -z ${FLATPAK_ID-} ]] || die 'Run outside the Flatpak sandbox with native Steam.'

    iso=$1
    shift
    destination=${XDG_DATA_HOME:-$HOME/.local/share}/toy-story-2
    while (( $# )); do
        [[ $# -ge 2 && -n $2 ]] || die "Missing value for $1"
        case $1 in
            --install-dir) destination=$2 ;;
            -f|--fix) fix=$2 ;;
            -i|--fix-ini) fix_ini=$2 ;;
            -d|--d7vk) d7vk=$2 ;;
            *) die "Unknown option: $1" ;;
        esac
        shift 2
    done
    extractor=$(command -v bsdtar || command -v 7zz || command -v 7z) ||
        die 'Install bsdtar or full 7zz/7z with ISO and ZIP support first.'
    find_wscript
    destination=$(realpath -ms -- "$destination")
    parent=$(dirname -- "$destination")
    mkdir -p -- "$parent"
    parent=$(realpath -e -- "$parent")
    destination=$parent/${destination##*/}
    [[ $destination != *'='* ]] || die 'Desktop executable paths cannot contain an equals sign.'
    stage=$(mktemp -d -- "$parent/.toy-story-2.XXXXXXXX")
    mkdir -- "$stage"/{iso,fix,d7vk}
    fetch_archive "$fix" "$stage/fix.zip"
    fetch_archive "$d7vk" "$stage/d7vk.zip"
    extract "$iso" "$stage/iso"
    extract "$stage/fix.zip" "$stage/fix" dsound.dll dsound.ini scripts/ToyStory2Fix.{asi,ini}
    extract "$stage/d7vk.zip" "$stage/d7vk" '*/x32/ddraw.dll'
    bad=$(find "$stage" \( ! -type d ! -type f -o -type f -links +1 \) -print -quit)
    [[ -z $bad ]] || die "Archive payload contains a link or special file: $bad"
    find "$stage" -type d -exec chmod 700 {} + -o -type f -exec chmod 600 {} +
    mapfile -d '' -t d7vk_dlls < <(find "$stage/d7vk" -type f -path '*/x32/ddraw.dll' -print0)
    [[ ${#d7vk_dlls[@]} == 1 && -s ${d7vk_dlls[0]} ]] ||
        die 'Unsupported D7VK archive: expected exactly one nonempty */x32/ddraw.dll.'
    game_exe=$(find "$stage/iso" -maxdepth 4 -type f -ipath '*/setup/toy2/hd/toy2.exe' -print -quit)
    [[ -n $game_exe ]] || die 'Expected Setup/Toy2/HD/toy2.exe in the ISO.'
    cd_dir=$(find "$stage/iso" -maxdepth 3 -type d -ipath '*/setup/toy2/cd' -print -quit)
    [[ -n $cd_dir ]] || die 'Expected Setup/Toy2/CD directory in the ISO.'
    mv -T -- "${game_exe%/*}" "$stage/game"
    mv -T -- "$cd_dir" "$stage/game/CD"
    icon=$(find "$stage/iso" -maxdepth 3 -type f -ipath '*/setup/media/toy2.ico' -print -quit)
    if [[ -n $icon ]]; then
        mv -T -- "$icon" "$stage/game/toy2.ico"
    fi
    cp -- "$stage/fix"/dsound.{dll,ini} "$stage/game/"
    mv -T -- "${d7vk_dlls[0]}" "$stage/game/ddraw.dll"
    printf 'd3d9.maxFrameRate = 60\n' > "$stage/game/dxvk.conf"
    mkdir -p -- "$stage/game/scripts"
    cp -- "$stage/fix"/scripts/ToyStory2Fix.{asi,ini} "$stage/game/scripts/"
    configure_loader
    if [[ -n $fix_ini ]]; then
        cp -T -- "$fix_ini" "$stage/game/scripts/ToyStory2Fix.ini"
    fi
    write_helpers
    # rmdir rejects files, links, mounts, and nonempty directories before the rename.
    if [[ -e $destination || -L $destination ]]; then
        rmdir -- "$destination" || die "Destination must be absent or empty: $destination"
    fi
    mv -T -- "$stage/game" "$destination"
    printf 'Installed Toy Story 2 at %s\n' "$destination"
    register "$destination"
}

# BASH_SOURCE is unset when the script is piped into bash.
if [[ ${BASH_SOURCE[0]:-$0} == "$0" ]]; then
    main "$@"
fi
