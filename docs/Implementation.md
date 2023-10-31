## ToDos

* [x] Caching
* [x] Performance Boost
* [x] Modularity (allow for later .app or .lib files)
* [ ] Implement missing functions
  - [ ] spaceUsed
  - [ ] write
  - [ ] rename
  - [x] getLabel
  - [x] setLabel

___
## Implemented Filesystem Component Functions 
Strike-through means implemented
### **spaceUsed():number** <br>
The currently used capacity of the file system, in bytes. <br>
### ~~open(path:string[, mode:string='r']):number~~ <br>
Opens a new file descriptor and returns its handle. <br>
### ~~seek(handle:number, whence:string, offset:number):number~~ <br>
Seeks in an open file descriptor with the specified handle. Returns the new pointer position. <br>
### ~~makeDirectory(path:string):boolean~~ <br>
Creates a directory at the specified absolute path in the file system. Creates parent directories, if necessary. <br>
### ~~exists(path:string):boolean~~ <br>
Returns whether an object exists at the specified absolute path in the file system. <br>
### ~~isReadOnly():boolean~~ <br>
Returns whether the file system is read-only. <br>
### **write(handle:number, value:string):boolean** <br>
Writes the specified data to an open file descriptor with the specified handle. <br>
### ~~spaceTotal():number~~ <br>
The overall capacity of the file system, in bytes. <br>
### ~~isDirectory(path:string):boolean~~ <br>
Returns whether the object at the specified absolute path in the file system is a directory. <br>
### **rename(from:string, to:string):boolean** <br>
Renames/moves an object from the first specified absolute path in the file system to the second. <br>
### ~~list(path:string):table~~ <br>
Returns a list of names of objects in the directory at the specified absolute path in the file system. <br>
### ~~lastModified(path:string):number~~ <br>
Returns the (real world) timestamp of when the object at the specified absolute path in the file system was modified. <br>
### ~~getLabel():string~~ <br>
Get the current label of the file system. <br>
## remove(path:string):boolean <br>
Removes the object at the specified absolute path in the file system. <br>
### ~~close(handle:number)~~ <br>
Closes an open file descriptor with the specified handle. <br>
### ~~size(path:string):number~~ <br>
Returns the size of the object at the specified absolute path in the file system. <br>
### ~~read(handle:number, count:number):string or nil~~ <br>
Reads up to the specified amount of data from an open file descriptor with the specified handle. Returns nil when EOF is reached. <br>
### ~~setLabel(value:string):string~~ <br>
Sets the label of the file system. Returns the new value, which may be truncated. <br>