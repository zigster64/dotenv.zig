# dotenv.zig
Load ENV vars from .env files on boot 

-- 


## Install

'''
zig fetch --save https://github.com/zigster64/dotenv.zig/archive/refs/tags/v0.1.0.tar.gz
'''

Then add to your build.zig

```zig
    const dep_opts = .{
        .target = target,
        .optimize = optimize,
    };

    const zts = b.dependency("dotenv", dep_opts);
    exe.root_module.addImport("dotenv", dotenv.module("dotenv"));
```

## Microlibray Alert

This is a MicroLibrary, the code is trivial enough.

Consider just copypasting the file `dotenv.zig` into your project instead of adding a microdependency. Up to you.

## Usage

```zig
const dotenv = @import("dotenv");

pub fn main() !void {
    // create an allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() != .ok) {
            logz.warn().boolean("memory_leak", true).src(@src()).log();
        }
    }

    // init the dotenv object - this will read the .env file at runtime
    const env = try dotenv.init(allocator);
    defer env.deinit();

    std.posix.getenv("DATABASE_NAME") // gets from ENV - lets say its value is "ABC"

    // gen "Env" vars
    var database_host = env.get("DATABASE_HOST") orelse "localhost";
    var database_name = env.get("DATABASE_NAME") orelse "zigzag-data";

    ... do stuff

    // change the value of "Env" vars
    try env.set("DATABASE_HOST", "postgres.local");

    // remove the value from the "Env" vars
    try env.delete("DATABASE_NAME");

    env.get("DATABASE_NAME"); // will return null, even if its in the original ENV vars
    std.posix.getenv("DATABASE_NAME"); // will return the original ENV var, so it = "ABC"
}
```

## How it works

On boot, loads the `.env` file into an internal hashmap of (key:string, value:string)

When the user calls `env.get(key)` it will :

- return the value from the hashmap, if found
- else, fallback to using posix.getenv()
- if neither found, return null

If a value is found, it will be returned as a null terminate string (to be compat with posix.getenv)

When the user calls `env.set(key,value)` - it clones the value passed, and adds it to the hashmap.

Because its cloning it, you can use temporary / stack variables with no problems.

When the user calls `env.delete(key)` it removes it from the hashmap, but also stores the fact its deleted in a 'deleted' hashmap 


