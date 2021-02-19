# .NET Core / .NET 5 - No Lock Deployment

A copyable set of files that can help deploy a .NET Core (or .Net 5) app with IIS without file locks or taking the site offline

## Arguments

### -publishTo
The path that your project will be published to

Type: `string`  
Expected: File path (e.g. `C:\Path\To\Site`)

### -projectPath
The path to your `.csproj` file

Type: `string`  
Expected: File string (e.g. `C:\Path\To\Site\Project.csproj` or `.\\Project.csproj`)

### -iisPath
The path to your IIS application (this is simply the folder path shown in IIS Manager)

Type: `string`  
Expected: File path (e.g. `Site` or `Site\Application-SubFolder`)

### -releaseType
**[Optional]** The type of release you're doing

Type: `string`  
Expected: `major`, `minor`, `patch` or `suffix`  
Default: `patch`

### -env
**[Optional]** The environment variable used to search for suffix files

Type: `string`  
Expected: Anything (e.g. `Production`, `Staging`, etc.)
Default: `Production`

## Versioning
File versioning is restricted to the below format. However, if you're familiar with powershell commands, you can ammend the `Publish.ps1` file to suit your own versioning.

`_version.txt` must follow `MAJOR.MINOR.PATCH`  
e.g. `1.0.0` or `0.0.0` or `101.232.5555`

You can expand on this with a suffix file. The suffix file allows you to add suffixes to your versioning. The `ENV` shown below must match the `-env` argument to be picked up on.

`_version-suffix-ENV.txt` must contain 0 or 1 `.` (dots). A dash is added for you  
e.g. `pr.1` or `a.1` or `beta.3` or just `0` if you want

If `-releaseType` is `suffix` and your version files consist of `1.0.0` and suffix of `a.2`. The reulst will be `1.0.0-a.3`