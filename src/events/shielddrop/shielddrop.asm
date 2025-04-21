#########################
## Shield Drop HIJACK INFO ##
#########################

ShieldDrop:
    # Store Stage, CPU, and FDD Toggles
    lwz r3, 0x0(r29)                                    # Send event struct
    mr r4, r26                                          # Send match struct
    li r5, -1                                           # Use chosen CPU
    li r6, Battlefield                                  # Use SSS Stage
    load r7, EventOSD_ShieldDrop
    li r8, 0                                            # Use Sopo bool
    bl InitializeMatch

    # STORE THINK FUNCTION
    bl ShieldDropLoad
    mflr r3
    stw r3, 0x44(r26)                                   # on match load

    b exit

########################
## Shield Drop LOAD FUNCT ##
########################
ShieldDropLoad:
    blrl

    backup

    # Schedule Think
    bl ShieldDropThink
    mflr r3
    li r4, 3                                            # Priority (After Interrupt)
    bl ShieldDropWindowInfo
    mflr r5
    bl ShieldDropWindowText
    mflr r6
    bl CreateEventThinkFunction

    b ShieldDropLoadExit

##########################
## Shield Drop THINK FUNCT ##
##########################

    # Registers
    .set MenuData, 26
    .set EventData, 31
    .set P1Data, 27
    .set P1GObj, 28
    .set P2Data, 29
    .set P2GObj, 30

    # Offsets
    .set FacingDirection, (MenuData_OptionMenuMemory+0x2)+0x0
    .set FacingDirectionToggled, (MenuData_OptionMenuToggled)+0x0

ShieldDropThink:
    blrl
    backup

    # INIT FUNCTION VARIABLES
    lwz EventData, 0x2c(r3)                             # backup data pointer in r31
    lwz MenuData, EventData_MenuDataPointer(EventData)

    bl GetAllPlayerPointers
    mr P1GObj, r3
    mr P1Data, r4
    mr P2GObj, r5
    mr P2Data, r6

    bl StoreCPUTypeAndZeroInputs

    # ON FIRST FRAME
    bl CheckIfFirstFrame
    cmpwi r3, 0x0
    beq ShieldDropThinkMain

    # Set Frame 1 As Over
    li r3, 0x1
    stb r3, 0x0(r31)
    bl ShieldDrop_Floats
    mflr r3
    bl InitializePositions
    # Clear Inputs
    bl RemoveFirstFrameInputs
    # Store Y Position to Last Known Y Position
    lfs f1, 0xB4(r29)
    stfs f1, 0x834(r29)
    # Save State
    addi r3, EventData, EventData_SaveStateStruct
    li r4, 1                                            # Override failsafe code
    bl SaveState_Save
    # Set Timer to -60
    li r3, -60
    stw r3, 0x4(r31)

ShieldDropThinkMain:
    .set AerialThinkStruct, 0x8

    bl GiveFullShields

    lbz r3, FacingDirectionToggled(MenuData)
    cmpwi r3, 0                                         # Check If Toggled An Option
    bne ShieldDropReset
    lbz r3, FacingDirectionToggled(MenuData)
    cmpwi r3, 0                                         # Check If Toggled An Option
    bne ShieldDropReset

    # Move Players Apart With DPad
    addi r3, EventData, 0x10                            # SaveState start
    bl AdjustResetDistance
    cmpwi r3, -1
    bne ShieldDropReset

ShieldDropThinkSequence:
    # Increment Timer
    lwz r20, 0x4(r31)                                   # get timer
    addi r20, r20, 0x1
    stw r20, 0x4(r31)                                   # store timer

    # Check if In Wait
    lwz r3, 0x10(r29)
    cmpwi r3, 0xE
    bne ShieldDropNoIntangibility
    # Give Intangibility in Wait
    mr r3, r30
    li r4, 0x2
    bl GiveInvincibility

ShieldDropNoIntangibility:
    # Check To Start Aerial
    cmpwi r20, 40
    blt ShieldDropThinkExit

    # Perform Aerial
    mr r3, r30
    addi r4, r31, AerialThinkStruct
    li r5, 0                                            # Random Attack
    bl PerformAerialThink

ShieldDropCheckToShield:
    # Check If CPU is done with Aerial Sequence
    lbz r3, AerialThinkStruct(r31)
    cmpwi r3, 0x0
    beq ShieldDropCheckToReset
    # Hold Shield
    li r3, 0xC0                                         # Hit L
    stw r3, 0x1A88(r29)                                 # Hold Shield

ShieldDropCheckToReset:
    cmpwi r20, 140
    bne ShieldDropThinkExit

ShieldDropReset:
    # Randomize Position
    li r3, 0x1                                          # Opposing Sides of Stage
    bl Randomize_LeftorRightSide
    # Adjust Facing Direction Based on Preference
    lbz r3, FacingDirection(MenuData)
    cmpwi r3, 0x1
    bne ShieldDropLoadState
    # Invert P1 Facing Direction
    lwz r3, 0x10(r31)
    lfs f1, 0x2C(r3)
    fneg f1, f1
    stfs f1, 0x2C(r3)

ShieldDropLoadState:
    # Backup P1 Analog Timers
    lwz r23, 0x620(r27)
    lwz r24, 0x624(r27)
    # Restore
    addi r3, EventData, EventData_SaveStateStruct
    bl SaveState_Load
    # Restore P1 Analog Timers
    lwz r23, 0x620(r27)
    lwz r24, 0x624(r27)
    # Reset Timer
    li r3, 50
    branchl r12, HSD_Randi
    li r4, 0
    sub r3, r4, r3
    stw r3, 0x4(r31)
    # Reset Aerial Move Think Struct
    li r3, 0
    stw r3, AerialThinkStruct(r31)

ShieldDropThinkExit:
    mr r3, MenuData
    bl ClearToggledOptions
    bl UpdateAllGFX
    restore
    blr

#################################

ShieldDrop_Floats:
    blrl
    .long 0xC0F9999A                                    # P1 X Position
    .long 0x40F9999A                                    # P2 X Position
    .long 0x425999b4                                    # Top Plat Y Position
    .long 0x425999b4                                    # Top Plat Y Position
    .long 0x3E99999A                                    # Y Vel to Attack
    .long 0x40A00000                                    # Distance from Ground to L Cancel

#################################

ShieldDropWindowInfo:
    blrl

    .long 0x0001FFFF                                    # 1 Window, Facing Direction Has 2 Options

################################

ShieldDropWindowText:
    blrl

######################
## Facing Direction ##
######################

    # Window Title = Facing Direction
    .long 0x46616369
    .long 0x6e672044
    .long 0x69726563
    .long 0x74696f6e
    .long 0x00000000

    # Option 1 = Towards
    .long 0x546f7761
    .long 0x72647300
    .long 0x00000000
    .long 0x00000000
    .long 0x00000000

    # Option 2 = Away
    .long 0x41776179
    .long 0x00000000
    .long 0x00000000
    .long 0x00000000
    .long 0x00000000

#################################

ShieldDropLoadExit:
    restore
    blr

################################################################################
