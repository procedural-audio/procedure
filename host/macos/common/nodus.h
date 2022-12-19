enum class EventTag: uint32_t {
    NoteOn,
    NoteOff,
    Pitch,
    Pressure,
};

struct NoteOn {
    uint64_t id;
    size_t offset;
    float pitch;
    float pressure;
};

struct NoteOff {
    uint64_t id;
    size_t offset;
};

struct Pitch {
    uint64_t id;
    size_t offset;
    float freq;
};

struct Pressure {
    uint64_t id;
    size_t offset;
    float pressure;
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
};

struct Event {
    EventTag tag;
    EventValue value;
};
