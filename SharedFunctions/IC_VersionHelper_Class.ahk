class IC_VersionHelper_Class
{
    ; Takes a version string in form of v#.#.# (versionTesting) and checks to see if it's as new as or newer than a second version string (versionComparing)
    ; Returns -1 if newer, 0 if older, 1 if the same
    IsVersionSameOrNewer(versionTesting, versionComparing)
    {
        versionTesting := StrSplit(versionTesting, ".", "v")
        versionComparing := StrSplit(versionComparing, ".", "v")
        ; compare each of the 3 version values starting from left
        loop, 3
        {
            ; is index value greater? version is newer
            if(versionTesting[A_Index] > versionComparing[A_Index])
                return -1
            ; is index value not set but comparing version test is set? version is newer
            else if (versionTesting[A_Index] == "" AND versionComparing[A_Index] != "")
                return -1
            ; is index value lower? version is newer
            else if (versionTesting[A_Index] < versionComparing[A_Index])
                return 0

        }
        ; 3 tested values are equal
        return 1
    }

    ; Takes a version string (versionTesting) and checks to see if it's newer than a second version string (versionComparing). Exception when version formats are different.
    IsVersionNewer(versionTesting, versionComparing)
    {
        if(versionTesting.MaxIndex() != versionComparing.MaxIndex())
            throw "Cannot compare versions with differing formats"
        versionTesting := StrSplit(versionTesting, ".", "v")
        versionComparing := StrSplit(versionComparing, ".", "v")
        loopSize := versionTesting.MaxIndex()
        loop, %loopSize%
        {
            if(versionTesting[A_Index] > versionComparing[A_Index])
                return true
            else if (versionTesting[A_Index] < versionComparing[A_Index])
                return false
        }
        ; same version
        return false
    }

}