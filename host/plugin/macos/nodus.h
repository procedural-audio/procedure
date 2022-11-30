enum class EventTag: uint32_t {
    NoteOn,
    NoteOff,
    Pitch,
    Pressure,
    Timbre,
    Controller,
    ProgramChange,
    None
};

struct Note {
    uint16_t id;
    float pitch;
    float pressure;
    float timbre;
};

struct NoteOn {
    Note note;
    uint16_t offset;
};

struct NoteOff {
    uint16_t id;
};

struct Pitch {
    uint16_t id;
    float freq;
};

struct Pressure {
    uint16_t id;
    float pressure;
};

struct Timbre {
    uint16_t id;
    float timbre;
};

struct Controller {
    uint16_t id;
    float value;
};

struct ProgramChange {
    uint16_t id;
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
    Timbre timbre;
    Controller controller;
    ProgramChange programChange;
};

struct Event {
    EventTag tag;
    EventValue value;
};
