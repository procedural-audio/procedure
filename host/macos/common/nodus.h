enum class NoteTag: uint32_t {
    NoteOn,
    NoteOff,
    Pitch,
    Pressure,
    Other
};

struct NoteOn {
    float pitch;
    float pressure;
};

struct NoteOff {
};

struct Pitch {
    float freq;
};

struct Pressure {
    float pressure;
};

struct Other {
    char* s;
    size_t size;
    float value;
};

/*struct FFIIOProcessor {
    uint64_t temp1;
    uint64_t temp2;
};*/

union NoteValue {
    NoteOn noteOn;
    NoteOff noteOff;
    Pitch pitch;
    Pressure pressure;
    Other other;
};

struct NoteMessage {
    uint64_t id;
    size_t offset;
    NoteTag tag;
    NoteValue value;
};
