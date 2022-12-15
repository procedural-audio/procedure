enum class EventTag: uint32_t {
    NoteOn,
    NoteOff,
    Pitch,
    Pressure,
    Controller,
    ProgramChange,
    None
};

struct Note {
    uint64_t id;
    float pitch;
    float pressure;
};

struct NoteOn {
    Note note;
    uint16_t offset;
};

struct NoteOff {
    uint64_t id;
};

struct Pitch {
    uint64_t id;
    float freq;
};

struct Pressure {
    uint64_t id;
    float pressure;
};

struct Controller {
    uint64_t id;
    float value;
};

struct ProgramChange {
    uint64_t id;
    uint8_t value;
};

struct FFIIOProcessor {
    uint64_t temp1;
    uint64_t temp2;
};

union EventValue {
    NoteOn noteOn;
    NoteOff noteOff;
    Pitch pitch;
    Pressure pressure;
    Controller controller;
    ProgramChange programChange;
};

struct Event {
    EventTag tag;
    EventValue value;
};
