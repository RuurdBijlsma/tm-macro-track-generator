namespace Package {
    void Test() {
        auto sourcePath = Meta::ExecutingPlugin().SourcePath;
        auto unpackageFolder = sourcePath + 'out/';
        string packagePath = sourcePath + 'out.opkg';

        if(!IO::FolderExists(unpackageFolder))
            IO::CreateFolder(unpackageFolder);

        string[] files = {sourcePath + 'test.txt', sourcePath + "test.jpg"};

        print("Create package");
        Package::Create(files, packagePath);

        auto pkgFiles = Package::List(packagePath);
        print("Package contents:");
        for(uint i = 0; i < pkgFiles.Length; i++) {
            print(tostring(i) + ": " + pkgFiles[i]);
        }

        print("Unpackage package");
        Package::Unpackage(packagePath, unpackageFolder);
    }

    void Unpackage(const string &in packageFile, string outputFolder) {
        IO::File file(packageFile);
        file.Open(IO::FileMode::Read);
        auto buffer = file.Read(file.Size());
        file.Close();
        auto headerLength = buffer.ReadInt32();
        auto header = buffer.ReadString(headerLength);
        auto headerParts = header.Split(':');

        for(uint i = 0; i < headerParts.Length; i++){ 
            auto headerPart = headerParts[i].Split('|');
            auto filename = headerPart[0];
            auto base64Size = Text::ParseInt(headerPart[1]);
            auto base64 = buffer.ReadString(base64Size);
            MemoryBuffer fileBuffer = MemoryBuffer();
            fileBuffer.WriteFromBase64(base64);
            
            if(!outputFolder.EndsWith("/"))
                outputFolder += "/";
            IO::File newFile(outputFolder + filename);
            newFile.Open(IO::FileMode::Write);
            newFile.Write(fileBuffer);
            newFile.Close();
        }
    }

    string[]@ List(const string &in packageFile) {
        IO::File file(packageFile);
        file.Open(IO::FileMode::Read);
        auto buffer = file.Read(file.Size());
        file.Close();
        auto headerLength = buffer.ReadInt32();
        auto header = buffer.ReadString(headerLength);
        auto headerParts = header.Split(':');

        string[]@ result = {};
        for(uint i = 0; i < headerParts.Length; i++){ 
            auto headerPart = headerParts[i].Split('|');
            auto filename = headerPart[0];
            result.InsertLast(filename);
        }
        return result;
    }

    void Create(string[]@ files, const string &in outputFile) {
        string[] filesBase64 = {};
        string[] filenames = {};
        for(uint i = 0; i < files.Length; i++){ 
            string filePath = files[i].Replace('\\', '/');
            auto fileParts = filePath.Split('/');
            auto filename = fileParts[fileParts.Length - 1];

            IO::File file(filePath);
            file.Open(IO::FileMode::Read);
            auto fileSize = file.Size();
            auto buffer = file.Read(fileSize);
            file.Close();

            filesBase64.InsertLast(buffer.ReadToBase64(fileSize));
            filenames.InsertLast(filename);
        }

        int64 allFilesSize = 0;
        string[] headerParts = {};
        for(uint i = 0; i < filenames.Length; i++) {
            string filename = filenames[i];
            auto base64 = filesBase64[i];
            headerParts.InsertLast(filename + "|" + base64.Length);
        }
        string header = string::Join(headerParts, ':');
        MemoryBuffer package = MemoryBuffer();

        print("WRITE header length: " + header.Length);
        print("WRITE header: " + header);

        package.Write(int32(header.Length));
        package.Write(header);
        for(uint i = 0; i < filesBase64.Length; i++) {
            package.Write(filesBase64[i]);
        }
        IO::File outFile(outputFile);
        outFile.Open(IO::FileMode::Write);
        outFile.Write(package);
        outFile.Close();
    }
}