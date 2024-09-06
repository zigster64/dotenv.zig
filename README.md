# dotenv.zig
Load ENV vars from .env files on boot 

-- 


## Install

```
zig fetch --save https://github.com/zigster64/dotenv.zig/archive/refs/tags/v0.1.0.tar.gz
```

Then add to your build.zig

```zig
    const zts = b.dependency("dotenv", .{ dependency options here );
    exe.root_module.addImport("dotenv", dotenv.module("dotenv"));
```

## 🤮 Microlibray Alert 🤮

This is a MicroLibrary, the code is trivial enough

Consider just copypasting the file `dotenv.zig` into your project instead of adding yet another microdependency

Its only about 20 lines of code

Up to you

## Usage

```zig
const dotenv = @import("dotenv");

pub fn main() !void {
    // create an allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer gpa.deinit();

    // init the dotenv object - this will read the .env file at runtime
    const env = try dotenv.init(allocator);
    defer env.deinit();

    // gen "Env" vars
    var database_host = env.get("DATABASE_HOST") orelse "localhost";
    var database_name = env.get("DATABASE_NAME") orelse "zigzag-data";

    ... do stuff

    // change the value of the DATABASE_HOST
    try env.put("DATABASE_HOST", "postgres.local");
}
```

## How it works

On boot, loads the `.env` file, and parses each line


If the line contains an '=' char, then it splits the line on that first '=' and then 
adds KEY : VALUE to the environment.

Uses `std.process.EnvMap` - which is an in-memory clone of the initial ENV


