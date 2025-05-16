#include "events.h"
#include "event_data.h"
#include "../build/generated_include_meta.h"
#include <stdint.h>
///////////////////////
/// Page Defintions ///
///////////////////////

// Minigames
static EventDesc *Minigames_Events[] = {
    &Eggs,
    &Multishine,
    &Reaction,
    &Ledgestall,
};
static EventPage Minigames_Page = {
    .name = "Minigames",
    .eventNum = (sizeof(Minigames_Events) / 4) - 1,
    .events = Minigames_Events,
};

// Page 2 Events
static EventDesc *General_Events[] = {
    &Lab,
    &LCancel,
    &Ledgedash,
    &Wavedash,
    &Combo,
    &AttackOnShield,
    &Reversal,
    &SDI,
    &Powershield,
    &Ledgetech,
    &AmsahTech,
    &ShieldDrop,
    &WaveshineSDI,
    &SlideOff,
    &GrabMash,
};
static EventPage General_Page = {
    .name = "General Tech",
    (sizeof(General_Events) / 4) - 1,
    General_Events,
};

// Page 3 Events
static EventDesc *Spacie_Events[] = {
    &TechCounter,
    &FoxEdgeguard,
    &FalcoEdgeguard,
    &SideBSweet,
    &EscapeSheik,
};
static EventPage Spacie_Page = {
    .name = "Character-specific Tech",
    (sizeof(Spacie_Events) / 4) - 1,
    Spacie_Events,
};

//////////////////
/// Page Order ///
//////////////////

EventPage **EventPages[] = {
    &Minigames_Page,
    &General_Page,
    &Spacie_Page,
};

int eventPageSize = (sizeof(EventPages)/sizeof(EventPages[0])) - 1;


int GetPageEventOffset(int pageID) {
    int eventIndex = 0;
    for(int i = 0;i < pageID; i++){ // Add the number of events for each previous page
        EventPage *thisPage = EventPages[i];
        eventIndex += (thisPage->eventNum) + 1;
    }
    return eventIndex;
}

int GetJumpTableOffset(int pageID, uint32_t jumpTableAddress, int eventID) {
    // jumpTableAddress is in r4 and is passed through without being used to simply the asm
    EventPage *thisPage = EventPages[pageID];
    EventDesc *thisEvent = thisPage->events[eventID];
    return (thisEvent->jumpTableIndex);
}

long* GetEventCharList(int eventID,int pageID) {
    EventPage *thisPage = EventPages[pageID];
    EventDesc *thisEvent = thisPage->events[eventID];
    EventCharList *thisEventCharList = thisEvent->CSSList;

    static long mask = 0;
    mask = 0;

    if (!thisEventCharList) return (long*)-1;

    for (int i = 0; i < 25; i++) {
      if (thisEventCharList->values[i]){
          mask |= CSSID_TABLE[i];
      }
    }

    return &mask;
}