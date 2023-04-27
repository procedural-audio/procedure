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
    uint32_t id;
    float value;
};

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
