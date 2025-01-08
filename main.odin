package pms

import "core:c"
import "core:os"
import "core:encoding/json"
import "core:strings"
import "core:io"
import "core:fmt"
import "core:bytes"
import "core:sys/posix"

PackageInfo :: struct {
    pkgname: string,
    version: string,
    source: []string,
    patches: []string, // This is optional, so it can be nil
    build: []string,
    depends: []string,
}

main :: proc() {
    if len(os.args) < 2 {
        fmt.println("Usage: pms <file_path>")// Maybe nice this up
        return
    }
    
    file_path := os.args[1]
    
    // Read the file
    data, ok := os.read_entire_file(file_path)
    if !ok {
        fmt.println("Error reading file")
        return
    }
    defer delete(data)
    
    filedata_str := string(data)
    
    // Decode JSON into a struct
    package_info: PackageInfo
    json_err := json.unmarshal(transmute([]u8)filedata_str, &package_info)
    if json_err != nil {
        fmt.println("Error decoding JSON:", json_err)
        return
    }
    
    // Print parsed data
    fmt.println("Package Name:", package_info.pkgname)
    fmt.println("Version:", package_info.version)
    fmt.println("Source URLs:")
    for source in package_info.source {
        fmt.println(" - ", source)
    }
    
    if len(package_info.patches) > 0 {
        fmt.println("Patches:")
        for patch in package_info.patches {
            fmt.println(" - ", patch)
        }
    } else {
        fmt.println("No patches provided.")
    }
    
    fmt.println("Build Steps:")
    for step in package_info.build {
        fmt.println(" - ", step)
    }
    
    fmt.println("Dependencies:")
    for dep in package_info.depends {
        fmt.println(" - ", dep)
    }
    
    // Prompt user for confirmation
    fmt.println("Continue? (Y/n)")
    
    buffer: [1]byte
    _, read_err := os.read(os.stdin, buffer[:])
    if read_err != 0 {
        fmt.println("Error reading input")
        return
    }
    
    yon := buffer[0]
    
    switch yon {
    case 'Y', 'y', '\n':
        for command in package_info.build {
            fmt.println("Executing:", command)
            
            // Execute command through shell
				cmd := command // TODO: Make this work
				ret := posix.execl("/bin/sh", "-c", cmd)
            if ret < 0 {
                fmt.println("Error executing command:", command)
                return
            }
        }
        fmt.println("Done!")
        
    case 'N', 'n':
        fmt.println("Aborted.")
        return
        
    case:
        fmt.println("Invalid input. Exiting.")
        return
    }
}
