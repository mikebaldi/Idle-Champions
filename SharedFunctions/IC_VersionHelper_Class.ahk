class IC_VersionHelper_Class
{
    ; Takes a version string in form of v#.#.# (versionTesting) and checks to see if it's newer than a second version string (versionComparing)
    IsVersionSameOrNewer(versionTesting, versionComparing)
    {
        versionTesting := StrSplit(versionTesting, ".", "v")
        versionComparing := StrSplit(versionComparing, ".", "v")
        ; compare each of the 3 version values
        loop, 3
        {
            version1 := versionTesting[A_Index]
            version2 := versionComparing[A_Index]
            if(versionTesting[A_Index] > versionComparing[A_Index])
                return true
            else if (versionTesting[A_Index] < versionComparing[A_Index])
                return false
        }
        ; 3 tested values are equal
        return true
    }
}