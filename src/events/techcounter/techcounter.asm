###################################
## Ledgetech Counter HIJACK INFO ##
###################################

LedgetechCounter:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, Marth.Ext                                    # Use marth
    li r6, -1                                           # Use chosen Stage
    load r7, EventOSD_LedgetechCounter
    li r8, 0                                            # Use Sopo bool
    bl InitializeMatch

# STORE THINK FUNCTION
LedgetechCounterStoreThink:
    bl LedgetechCounterLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

##################################
## Ledgetech Counter LOAD FUNCT ##
##################################
LedgetechCounterLoad:
    blrl

    backup

    # Schedule Think
    bl LedgetechCounterThink
    mflr r3
    li r4, 3                                            # Priority (After EnvCOllision)
    li r5, 0
    bl CreateEventThinkFunction
    b LedgetechCounterThink_Exit

###################################
## Ledgetech Counter THINK FUNCT ##
###################################

LedgetechCounterThink:
    blrl

    # Registers
    .set EventConstants, 25
    .set MenuData, 26
    .set EventData, 31
    .set P1Data, 27
    .set P1GObj, 28
    .set P2Data, 29
    .set P2GObj, 30

    # Event Data Offsets
    .set EventState, 0x0
    .set EventState_OnRebirthPlat, 0x0
    .set EventState_Recovering, 0x1
    .set MarthState, 0x1
    .set MarthState_Wait, 0x0
    .set MarthState_Attacked, 0x1
    .set Timer, 0x2

    backup

    # INIT FUNCTION VARIABLES
    lwz EventData, 0x2c(r3)                             # backup data pointer in r31

    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4
    mr P2GObj, r5
    mr P2Data, r6

    lwz MenuData, EventData_MenuDataPointer(EventData)

    bl LedgetechCounter_Constants
    mflr EventConstants

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq LedgetechCounterThink_Start
    # Random Side of Stage
    li r3, 2
    branchl r12, HSD_Randi
    bl Ledgetech_InitializePositions
    # Move Marth forward a bit
    lfs f1, 0x2C(P2Data)
    lfs f2, 0x4(EventConstants)
    fmuls f1, f1, f2
    lfs f2, 0xB0(P2Data)
    fadds f1, f1, f2
    stfs f1, 0xB0(P2Data)
    # Move Falco down a bit
    lfs f1, 0x8(EventConstants)
    lfs f2, 0xB4(P1Data)
    fadds f1, f1, f2
    stfs f1, 0xB4(P1Data)
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Save State
    addi r3, EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Init Score Count
    lhz r3, -0x4ea8(r13)
    branchl r12, HUD_KOCounter_UpdateKOs

LedgetechCounterThink_Start:
    # Reset if anyone died
    bl IsAnyoneDead
    cmpwi r3, 0
    bne LedgetechCounterThink_Restore

    # Switch case for state of event
    lbz r3, EventState(EventData)
    cmpwi r3, EventState_OnRebirthPlat
    beq LedgetechCounterThink_OnRebirthPlat
    cmpwi r3, EventState_Recovering
    beq LedgetechCounterThink_Recovering
    b LedgetechCounterThink_CheckForTimer

###########################################
LedgetechCounterThink_OnRebirthPlat:
    # Check if exited RebirthWait
    lwz r3, 0x10(P1Data)
    cmpwi r3, ASID_RebirthWait
    beq LedgetechCounterThink_OnRebirthPlat_ExtendTimer
    # Change Event State
    li r3, EventState_Recovering
    stb r3, EventState(EventData)
    b LedgetechCounterThink_CheckForTimer

LedgetechCounterThink_OnRebirthPlat_ExtendTimer:
    # Extend RebithWait Timer
    li r3, 2
    stw r3, 0x2340(P1Data)
    b LedgetechCounterThink_CheckForTimer

###########################################

###########################################
LedgetechCounterThink_Recovering:
    # Check if marth acted already
    lbz r3, MarthState(EventData)
    cmpwi r3, MarthState_Wait
    bne LedgetechCounterThink_CheckForTimer

    # Check P1s Distance from Marth
    addi r3, P1Data, 0xB0
    addi r4, P2Data, 0xB0
    bl GetDistance
    lfs f2, 0x0(EventConstants)
    fcmpo cr0, f1, f2
    bgt LedgetechCounterThink_CheckForTimer
    # P1 is in range, use down B
    li r3, 0x200
    stw r3, CPU_HeldButtons(P2Data)
    li r3, -127
    stb r3, CPU_AnalogY(P2Data)
    # Set as attacking
    li r3, MarthState_Attacked
    stb r3, MarthState(EventData)
    # Start Timer
    li r3, 70
    stb r3, Timer(EventData)

    b LedgetechCounterThink_CheckForTimer

############################################

LedgetechCounterThink_CheckForTimer:
    # Check Timer
    lbz r3, Timer(EventData)
    cmpwi r3, 0
    beq LedgetechCounterThink_Exit
    # Decrement
    subi r3, r3, 1
    stb r3, Timer(EventData)
    cmpwi r3, 0
    bne LedgetechCounterThink_Exit

LedgetechCounterThink_Restore:
    # Load State
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    # Random Side of Stage
    li r3, 2
    branchl r12, HSD_Randi
    bl Ledgetech_InitializePositions
    # Move Marth forward a bit
    lfs f1, 0x2C(P2Data)
    lfs f2, 0x4(EventConstants)
    fmuls f1, f1, f2
    lfs f2, 0xB0(P2Data)
    fadds f1, f1, f2
    stfs f1, 0xB0(P2Data)
    # Move Falco down a bit
    lfs f1, 0x8(EventConstants)
    lfs f2, 0xB4(P1Data)
    fadds f1, f1, f2
    stfs f1, 0xB4(P1Data)

    # Reset Variables
    li r3, EventState_OnRebirthPlat
    stb r3, EventState(EventData)
    li r3, MarthState_Wait
    stb r3, MarthState(EventData)
    li r3, 0
    stb r3, Timer(EventData)

LedgetechCounterThink_Exit:
    restore
    blr

######
LedgetechCounter_Constants:
    blrl
    .float 33                                           # Mm away from fox to init counter
    .float 5                                            # Mm to move marth forward after placing on ledge
    .float -15                                          # Mm to move spacies down after placing in the air

######
