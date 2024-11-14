<div align="center">
<h1>Scroll - A <i>RUNTIME INDEXED</i> ARCHIVE</h1> 
(tool and library)
</div>

## What is Scroll
Scroll is a tool + library duo for creating archives and then accessing them at runtime and extracting data by the data index (relative path).  
Using the tool `scroll` you can easily create an archive file `sroll <archive_name> <root_directory>` and then using `libscroll` you can access that
data and extract it (as bytes) by the index (relative path). For more information look at the test cases inside `src/lib.zig`.

## Why is Scroll
My main reason behind **Scroll** is using it alongside **WebUI** for shipping binaries. No one likes having to ship their binary alongside a folder 
full of .html and .js files. For now it only works by providing a `fs.File` but I am working on a version that works directly with bytes as well for 
languages that support direct file import (like zig's `@embeedFile`). Also more works is needed to get the library to work well with other languages, 
for now only supporting zig.

## Instalation:
For ZIG version `0.13.0`  
Run the following command in the **root folder** of your zig project:
```bash
zig fetch --save https://github.com/OsakiTsukiko/scroll/archive/main.tar.gz
```
and then add the following to you `build.zig` file:
```zig
pub fn build(b: *std.Build) void {
	// ...
	const scroll_dependency = b.dependency("scroll", .{});
	const exe = b.addExecutable(.{
		// ...
	});
	exe.root_module.addImport("scroll", scroll_dependency.module("scroll"));
	// ...
}
```
now you can use scroll inside your source files:
```zig
const RuntimeArchive = @import("scroll").RuntimeArchive;
```
