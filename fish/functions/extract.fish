# ~/.config/fish/functions/extract.fish
function extract --description "Extract various archive formats"
    if test (count $argv) -eq 0
        echo "Usage: extract <archive_file> [destination]"
        echo ""
        echo "Supported formats:"
        echo "  .tar.gz, .tgz     - tar gzip"
        echo "  .tar.bz2, .tbz2   - tar bzip2"
        echo "  .tar.xz, .txz     - tar xz"
        echo "  .tar              - tar"
        echo "  .zip              - zip"
        echo "  .rar              - rar"
        echo "  .7z               - 7zip"
        echo "  .gz               - gzip"
        echo "  .bz2              - bzip2"
        echo "  .xz               - xz"
        echo "  .Z                - compress"
        echo "  .deb              - debian package"
        echo "  .rpm              - rpm package"
        return 1
    end
    
    set archive $argv[1]
    
    # Check if file exists
    if not test -f "$archive"
        echo "Error: File '$archive' not found"
        return 1
    end
    
    # Set destination directory
    if test (count $argv) -gt 1
        set dest $argv[2]
        mkdir -p "$dest"
    else
        set dest "."
    end
    
    # Get file extension — check compound extensions first, then single
    set extension (string lower (string match -r '\.tar\.\w+$' "$archive"))
    if test -z "$extension"
        set extension (string lower (string match -r '\.[^.]*$' "$archive"))
    end

    switch "$extension"
        case ".tgz" ".tar.gz"
            if command -q tar
                echo "Extracting tar.gz archive..."
                tar -xzf "$archive" -C "$dest"
            else
                echo "Error: tar command not found"
                return 1
            end
            
        case ".tbz2" ".tar.bz2"
            if command -q tar
                echo "Extracting tar.bz2 archive..."
                tar -xjf "$archive" -C "$dest"
            else
                echo "Error: tar command not found"
                return 1
            end
            
        case ".txz" ".tar.xz"
            if command -q tar
                echo "Extracting tar.xz archive..."
                tar -xJf "$archive" -C "$dest"
            else
                echo "Error: tar command not found"
                return 1
            end
            
        case ".tar"
            if command -q tar
                echo "Extracting tar archive..."
                tar -xf "$archive" -C "$dest"
            else
                echo "Error: tar command not found"
                return 1
            end
            
        case ".zip"
            if command -q unzip
                echo "Extracting zip archive..."
                unzip -q "$archive" -d "$dest"
            else
                echo "Error: unzip command not found"
                return 1
            end
            
        case ".rar"
            if command -q unrar
                echo "Extracting rar archive..."
                unrar x "$archive" "$dest/"
            else
                echo "Error: unrar command not found (install unrar)"
                return 1
            end
            
        case ".7z"
            if command -q 7z
                echo "Extracting 7z archive..."
                7z x "$archive" -o"$dest"
            else
                echo "Error: 7z command not found (install p7zip)"
                return 1
            end
            
        case ".gz"
            if command -q gunzip
                echo "Extracting gz file..."
                if test "$dest" = "."
                    gunzip -k "$archive"
                else
                    gunzip -c "$archive" > "$dest/"(basename "$archive" .gz)
                end
            else
                echo "Error: gunzip command not found"
                return 1
            end
            
        case ".bz2"
            if command -q bunzip2
                echo "Extracting bz2 file..."
                if test "$dest" = "."
                    bunzip2 -k "$archive"
                else
                    bunzip2 -c "$archive" > "$dest/"(basename "$archive" .bz2)
                end
            else
                echo "Error: bunzip2 command not found"
                return 1
            end
            
        case ".xz"
            if command -q unxz
                echo "Extracting xz file..."
                if test "$dest" = "."
                    unxz -k "$archive"
                else
                    unxz -c "$archive" > "$dest/"(basename "$archive" .xz)
                end
            else
                echo "Error: unxz command not found"
                return 1
            end
            
        case ".Z"
            if command -q uncompress
                echo "Extracting Z file..."
                if test "$dest" = "."
                    uncompress -c "$archive" > (basename "$archive" .Z)
                else
                    uncompress -c "$archive" > "$dest/"(basename "$archive" .Z)
                end
            else
                echo "Error: uncompress command not found"
                return 1
            end
            
        case ".deb"
            if command -q ar
                echo "Extracting deb package..."
                cd "$dest"
                ar x (realpath "$archive")
                cd -
            else
                echo "Error: ar command not found"
                return 1
            end
            
        case ".rpm"
            if command -q rpm2cpio && command -q cpio
                echo "Extracting rpm package..."
                cd "$dest"
                rpm2cpio (realpath "$archive") | cpio -idmv
                cd -
            else
                echo "Error: rpm2cpio and/or cpio commands not found"
                return 1
            end
            
        case '*'
            echo "Error: Unsupported archive format for '$archive'"
            echo "Run 'extract' without arguments to see supported formats"
            return 1
    end
    
    if test $status -eq 0
        echo "Successfully extracted '$archive'"
        if test "$dest" != "."
            echo "Files extracted to: $dest"
        end
    else
        echo "Error: Failed to extract '$archive'"
        return 1
    end
end
