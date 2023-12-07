Class CSharpRNG
{
    static MBIG := 2147483647
    static MSEED := 161803398
    static MZ := 0

    inext := 0
    inextp := 0
    SeedArray := []

    __New(Seed)
    {
        seedArray := this.SeedArray
        subtraction := (Seed == -2147483648) ? 2147483647 : Abs(Seed)
        mj := this.MSEED - subtraction
        seedArray[55] := mj
        mk := 1
        Loop, 54
        {
            ii := Mod((21 * A_Index), 55)
            seedArray[ii] := mk
            mk := mj - mk
            if (mk < 0)
                mk += this.MBIG
            mj := seedArray[ii]
        }
        Loop, 4
        {
            Loop, 55
            {
                seedArray[A_Index] -= seedArray[1 + Mod(A_Index + 30, 55)]
                if (seedArray[A_Index] < 0)
                    seedArray[A_Index] += this.MBIG
            }
        }
        this.inext := 0
        this.inextp := 21
    }

    Sample()
    {
        return this.InternalSample() / this.MBIG
    }

    InternalSample()
    {
        seedArray := this.SeedArray
        locINext := this.inext
        locINextp := this.inextp
        if (++locINext >= 56)
            locINext := 1
        if (++locINextp >= 56)
            locINextp := 1
        retVal := seedArray[locINext] - seedArray[locINextp]
        if (retVal == this.MBIG)
            retVal--
        if (retVal < 0)
            retVal += this.MBIG
        seedArray[locINext] := retVal
        this.inext := locINext
        this.inextp := locINextp
        return retVal
    }

    Next()
    {
        return this.InternalSample()
    }

    GetSampleForLargeRange()
    {
        result := this.InternalSample()
        if (Mod(this.InternalSample(), 2) == 0)
            result := -result
        return (result + 2147483646) / 4294967293
    }

    NextRange(minValue, maxValue)
    {
        if (minValue > maxValue)
            throw "'" . minValue . "' cannot be greater than " . maxValue . "."
        range := maxValue - minValue
        if (range <= 2147483647)
            return Floor(this.Sample() * range) + minValue
        else
            return Floor(this.GetSampleForLargeRange() * range + minValue)
    }

    NextPositive(maxValue)
    {
        if (maxValue < 0)
            throw "'" . maxValue . "' must be greater than zero."
        return Floor(this.Sample() * maxValue)
    }

    NextDouble()
    {
        return this.Sample()
    }
}