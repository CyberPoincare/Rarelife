// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library RarelifeStructs {

    struct SAbilityScore {
        uint32 _chr; // charm CHR
        uint32 _int; // intelligence INT
        uint32 _str; // strength STR
        uint32 _mny; // money MNY

        uint32 _spr; // happy SPR
        uint32 _lif; // health LIF
        //uint32 _age; // age AGE
    }

    struct SAbilityModifiers {
        int32 _chr;
        int32 _int;
        int32 _str;
        int32 _mny;

        int32 _spr;
        int32 _lif;
        int32 _age;
    }
}
