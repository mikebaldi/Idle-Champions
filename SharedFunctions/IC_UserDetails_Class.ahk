
;a couple classes to store and manipulate data from user details calls.

class IC_UserDetails_Class
{
    __new( UserDetails )
    {
        this.gemsSpent := new _classValueWithStart( userDetails.details.red_rubies_spent )
        this.gems := new _classValueWithStart( userDetails.details.red_rubies )
        this.silverChestsOpened := new _classValueWithStart( userDetails.details.stats.chests_opened_type_1 + 0 )
        this.silverChests := new _classValueWithStart( userDetails.details.chests.1 )
        this.goldChestsOpened := new _classValueWithStart( userDetails.details.stats.chests_opened_type_2 + 0 )
        this.goldChests := new _classValueWithStart( userDetails.details.chests.2 )
        this.instanceID := userDetails.details.instance_id
        this.activeInstanceID := userDetails.details.active_game_instance_id
        ;this.briv_steelbones_stacks := new _classValueWithStart( userDetails.details.stats.briv_steelbones_stacks + 0 )
        ;this.briv_sprint_stacks := new _classValueWithStart( userDetails.details.stats.briv_sprint_stacks + 0 )

        for k, v in userDetails.details.game_instances
        {
            if (v.game_instance_id == this.activeInstanceID) 
            {
                this.currentAdventure := v.current_adventure_id
            }
        }
        formationString := ""
        this.formationArray := {}
        for k, v in userDetails.details.formation
        {
            formationString .= v . ", "
            this.formationArray.Push( v )
        }
        this.formationString := RTrim( formationString, ", " )

        
        i := 0
        for k, v in userDetails.details.buffs
        {
            if ( v.buff_id == "74" )
            {
                this.smallSpeedPotCount := new _classValueWithStart( v.inventory_amount + 0 )
                ++i
            }
            else if ( v.buff_id == "75" )
            {
                this.medSpeedPotCount := new _classValueWithStart( v.inventory_amount + 0 )
                ++i
            }
            else if ( v.buff_id == "76" )
            {
                this.largeSpeedPotCount := new _classValueWithStart( v.inventory_amount + 0 )
                ++i
            }else if ( v.buff_id == "77" )
            {
                this.hugeSpeedPotCount := new _classValueWithStart( v.inventory_amount + 0 )
                ++i
            }
            if ( i == 4 )
                Break
        }
        userDetails := ""
        return this
    }

    SetUserDetails( UserDetails )
    {
        if( IsObject( userDetails ) )
        {
            this.silverChestsOpened.Current := userDetails.details.stats.chests_opened_type_1 + 0
            this.silverChests.Current := userDetails.details.chests.1
            this.goldChestsOpened.Current := userDetails.details.stats.chests_opened_type_2 + 0
            this.goldChests.Current := userDetails.details.chests.2
            this.gemsSpent.Current := userDetails.details.red_rubies_spent
            this.gems.Current := userDetails.details.red_rubies
            this.instanceID := userDetails.details.instance_id
            this.activeInstanceID := userDetails.details.active_game_instance_id
            this.currentTime := userDetails.current_time
            this.processingTime := userDetails.processing_time
            ;this.briv_steelbones_stacks.Current := userDetails.details.stats.briv_steelbones_stacks + 0
            ;this.briv_sprint_stacks.Current := userDetails.details.stats.briv_sprint_stacks + 0

            for k, v in userDetails.details.game_instances
            {
                if (v.game_instance_id == this.activeInstanceID) 
                {
                    this.currentAdventure := v.current_adventure_id
                }
            }
            formationString := ""
            this.formationArray := {}
            for k, v in userDetails.details.formation
            {
                formationString .= v . ", "
                this.formationArray.Push( v )
            }
            this.formationString := RTrim( formationString, ", " )

            
            i := 0
            for k, v in userDetails.details.buffs
            {
                if ( v.buff_id == "74" )
                {
                    this.smallSpeedPotCount.Current := v.inventory_amount + 0
                    ++i
                }
                else if ( v.buff_id == "75" )
                {
                    this.medSpeedPotCount.Current := v.inventory_amount + 0
                    ++i
                }
                else if ( v.buff_id == "76" )
                {
                    this.largeSpeedPotCount.Current := v.inventory_amount + 0
                    ++i
                }else if ( v.buff_id == "77" )
                {
                    this.hugeSpeedPotCount.Current := v.inventory_amount + 0
                    ++i
                }
                if ( i == 4 )
                    Break
            }
            userDetails := ""
            return
        }
        return
    }
}

class _classValueWithStart
{
    __new( value )
    {
        this.Current := value
        this.Start := value
        return this
    }

    Difference()
    {
        return this.Current - this.Start
    }
}