; This file is what is executed as a mod to BrivGemFarm when it starts.

; The #include here is required for injection 
#include %A_LineFile%\..\Example_BrivGemFarm_Extends_Functions.ahk
; Set the new extended class to replace the one currently being used.
; This must be done after any addons that also modify classes, meaning addon order is important!

; These styles of functionality can easily conflict with other addons that attempt to do a similar thing.

; In order to add the modifications to Briv Gem Farm one of two methods can be used.

; 1. Create a instance of the updated class you want to use and overwrite the global variable that was used by the base class.

; Uncomment the line below to use method #1
global g_SF := new IC_Example_SharedFunctions_Class 

; 2. Use the UpdateClassFunctions function to copy the new functions into what is stored in the global variable.
; This method doesn't require keeping track of other extended classes from other addons, but can still conflict with addons that overwrite the same function.

; Uncomment the two lines below to use method #2
;#include %A_LineFile%\..\..\..\..\SharedFunctions\SH_UpdateClass.ahk
;SH_UpdateClass.UpdateClassFunctions(g_SF, IC_Example_SharedFunctions_Class)