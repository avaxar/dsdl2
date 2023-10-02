/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.mixer;
@safe:

// dfmt off
import bindbc.sdl;
static if (bindSDLMixer):
// dfmt on

import dsdl2.sdl;
import dsdl2.audio;

import core.memory : GC;
import std.conv : to;
import std.format : format;
import std.string : toStringz;
import std.typecons : Tuple, tuple;

version (BindSDL_Static) {
}
else {
    /++
     + Loads the SDL2_mixer shared dynamic library, which wraps bindbc-sdl's `loadSDLMixer` function
     +
     + Unless if bindbc-sdl is on static mode (by adding a `BindSDL_Static` version), this function will exist and must
     + be called before any calls are made to the library. Otherwise, a segfault will happen upon any function calls.
     +
     + Params:
     +   libName = name or path to look the SDL2_mixer SO/DLL for, otherwise `null` for default searching path
     + Throws: `dsdl2.SDLException` if failed to find the library
     +/
    void loadSO(string libName = null) @trusted {
        SDLMixerSupport current = libName is null ? loadSDLMixer() : loadSDLMixer(libName.toStringz());
        if (current == sdlMixerSupport) {
            return;
        }

        Version wanted = Version(sdlMixerSupport);
        if (current == SDLMixerSupport.badLibrary) {
            import std.stdio : writeln;

            writeln("WARNING: dsdl2 expects SDL_mixer ", wanted.format(), ", but got ", getVersion().format(), ".");
        }
        else if (current == SDLMixerSupport.noLibrary) {
            throw new SDLException("No SDL2_mixer library found, especially of version " ~ wanted.format(),
                __FILE__, __LINE__);
        }
    }
}

/++
 + Wraps `Mix_Init` which initializes selected SDL2_mixer audio format subsystems
 +
 + Params:
 +   flac = selects the `MIX_INIT_FLAC` subsystem
 +   mod = selects the `MIX_INIT_MOD` subsystem
 +   mp3 = selects the `MIX_INIT_MP3` subsystem
 +   ogg = selects the `MIX_INIT_OGG` subsystem
 +   mid = selects the `MIX_INIT_FLUIDSYNTH` (for SDL_mixer below 2.0.2) / `MIX_INIT_MID` subsystem
 +   opus = selects the `MIX_INIT_OPUS` subsystem (from SDL_mixer 2.0.4)
 +   everything = selects every available subsystem
 + Throws: `dsdl2.SDLException` if any selected subsystem failed to initialize
 + Example:
 + ---
 + dsdl2.mixer.init(everything : true);
 + ---
 +/
void init(bool flac = false, bool mod = false, bool mp3 = false, bool ogg = false, bool mid = false,
    bool opus = false, bool everything = false) @trusted
in {
    static if (sdlMixerSupport < SDLMixerSupport.v2_0_4) {
        assert(opus == false);
    }
    else {
        if (opus) {
            assert(dsdl2.mixer.getVersion() >= Version(2, 0, 4));
        }
    }
}
do {
    int flags = 0;

    flags |= flac ? MIX_INIT_FLAC : 0;
    flags |= mod ? MIX_INIT_MOD : 0;
    flags |= mp3 ? MIX_INIT_MP3 : 0;
    flags |= ogg ? MIX_INIT_OGG : 0;
    flags |= everything ? MIX_INIT_FLAC | MIX_INIT_MOD | MIX_INIT_MP3 | MIX_INIT_OGG : 0;

    static if (sdlMixerSupport >= SDLMixerSupport.v2_0_2) {
        flags |= mid ? MIX_INIT_MID : 0;
        flags |= everything ? MIX_INIT_MID : 0;
    }
    else {
        flags |= mid ? MIX_INIT_FLUIDSYNTH : 0;
        flags |= everything ? MIX_INIT_FLUIDSYNTH : 0;
    }

    static if (sdlMixerSupport >= SDLMixerSupport.v2_0_4) {
        flags |= opus ? MIX_INIT_OPUS : 0;
        flags |= everything ? MIX_INIT_OPUS : 0;
    }

    if (Mix_Init(flags) != 0) {
        throw new SDLException;
    }
}

version (unittest) {
    static this() {
        version (BindSDL_Static) {
        }
        else {
            dsdl2.mixer.loadSO();
        }

        dsdl2.mixer.init(everything : true);
    }
}

/++
 + Wraps `Mix_Quit` which entirely deinitializes SDL2_mixer
 +/
void quit() @trusted {
    Mix_Quit();
}

version (unittest) {
    static ~this() {
        dsdl2.mixer.quit();
    }
}

/++
 + Wraps `Mix_Linked_Version` which gets the version of the linked SDL2_mixer library
 +
 + Returns: `dsdl2.Version` of the linked SDL2_mixer library
 +/
Version getVersion() @trusted {
    return Version(*Mix_Linked_Version());
}

enum channels = cast(ubyte) MIX_CHANNELS; /// Alias to `MIX_CHANNELS`
enum defaultFrequency = cast(uint) MIX_DEFAULT_FREQUENCY; /// Alias to `MIX_DEFAULT_FREQUENCY`
enum defaultFormat = cast(AudioFormat) MIX_DEFAULT_FORMAT; /// Alias to `MIX_DEFAULT_FORMAT`
enum maxVolume = cast(ubyte) MIX_MAX_VOLUME; /// Alias to `MIX_MAX_VOLUME`

/++
 + D enum that wraps `Mix_Fading`
 +/
enum Fading {
    /++
     + Wraps `MIX_*` enumeration constants
     +/
    noFading = MIX_NO_FADING,
    fadingIn = MIX_FADING_IN, /// ditto
    fadingOut = MIX_FADING_OUT /// ditto
}

/++
 + D enum that wraps `Mix_MusicType`
 +/
enum MusicType {
    /++
     + Wraps `MUS_*` enumeration constants
     +/
    none = MUS_NONE,
    cmd = MUS_CMD, /// ditto
    wav = MUS_WAV, /// ditto
    mod = MUS_MOD, /// ditto
    mid = MUS_MID, /// ditto
    ogg = MUS_OGG, /// ditto
    mp3 = MUS_MP3, /// ditto
    flac = MUS_FLAC, /// ditto

    opus = 10 /// Wraps `MUS_OPUS` (from SDL_mixer 2.0.4)
}

/++
 + Wraps `Mix_OpenAudio` which opens the default audio device for playback by SDL_mixer
 +
 + Params:
 +   frequency = audio playback frequency in Hz
 +   format = `dsdl2.AudioFormat` enumeration indicating the scalar type of each audio sample
 +   channels = channels for `dsdl2.mixer.Chunk` playback (1 for mono; 2 for stereo)
 +   chunkSize = audio buffer size
 + Throws: `dsdl2.SDLException` if failed to open default audio device
 +/
void openAudio(uint frequency, AudioFormat format, uint channels, uint chunkSize) @trusted {
    if (Mix_OpenAudio(frequency.to!int, cast(ushort) format, channels.to!int, chunkSize.to!int) != 0) {
        throw new SDLException;
    }
}

static if (sdlMixerSupport >= SDLMixerSupport.v2_0_2) {
    /++
     + Wraps `Mix_OpenAudioDevice` (from SDL_mixer 2.0.2) which opens a selected audio device for playback by SDL_mixer
     +
     + Params:
     +   frequency = audio playback frequency in Hz
     +   format = `dsdl2.AudioFormat` enumeration indicating the scalar type of each audio sample
     +   channels = channels for `dsdl2.mixer.Chunk` playback (1 for mono; 2 for stereo)
     +   chunkSize = audio buffer size
     +   deviceName = name of the selected device
     +   allowFrequencyChange = adds `SDL_AUDIO_ALLOW_FREQUENCY_CHANGE` flag
     +   allowFormatChange = adds `SDL_AUDIO_ALLOW_FORMAT_CHANGE` flag
     +   allowChannelsChange = adds `SDL_AUDIO_ALLOW_CHANNELS_CHANGE` flag
     +   allowSamplesChange = adds `SDL_AUDIO_ALLOW_SAMPLES_CHANGE` flag (from SDL_mixer 2.0.9)
     +   allowAnyChange = adds `SDL_AUDIO_ALLOW_ANY_CHANGE` flag
     + Throws: `dsdl2.SDLException` if failed to open the selected audio device
     +/
    void openAudioDevice(uint frequency, AudioFormat format, uint channels, uint chunkSize, string deviceName,
        bool allowFrequencyChange = false, bool allowFormatChange = false, bool allowChannelsChange = false,
        bool allowSamplesChange = false, bool allowAnyChange = false) @trusted
    in {
        assert(dsdl2.mixer.getVersion() >= Version(2, 0, 2));

        static if (sdlSupport < SDLSupport.v2_0_9) {
            assert(allowSamplesChange == false);
        }
        else {
            if (allowSamplesChange) {
                assert(dsdl2.mixer.getVersion() >= Version(2, 0, 9));
            }
        }
    }
    do {
        int changeFlags = 0;
        changeFlags |= allowFrequencyChange ? SDL_AUDIO_ALLOW_FREQUENCY_CHANGE : 0;
        changeFlags |= allowFormatChange ? SDL_AUDIO_ALLOW_FORMAT_CHANGE : 0;
        changeFlags |= allowChannelsChange ? SDL_AUDIO_ALLOW_CHANNELS_CHANGE : 0;
        changeFlags |= allowAnyChange ? SDL_AUDIO_ALLOW_ANY_CHANGE : 0;

        static if (sdlSupport >= SDLSupport.v2_0_9) {
            changeFlags |= allowSamplesChange ? SDL_AUDIO_ALLOW_SAMPLES_CHANGE : 0;
        }

        if (Mix_OpenAudioDevice(frequency.to!int, cast(ushort) format, channels.to!int, chunkSize.to!int,
                deviceName.toStringz(), changeFlags) != 0) {
            throw new SDLException;
        }
    }
}

/++
 + Wraps `Mix_AllocateChannels` which changes the amount of track channels managed by SDL_mixer
 +
 + Params:
 +   channels = new amount of track channels (not the same as device channels)
 +/
void allocateChannels(uint channels) @trusted {
    Mix_AllocateChannels(channels.to!int);
}

/++
 + Wraps `Mix_ReserveChannels` which reserves the first track channels managed by SDL_mixer for the application
 +
 + Params:
 +   channels = amount of the first track channels to reserve (not the same as device channels)
 +/
void reserveChannels(uint channels) @trusted {
    Mix_ReserveChannels(channels.to!int);
}

private alias MixerSpec = Tuple!(uint, "frequency", AudioFormat, "format", uint, "channels");

/++
 + Wraps `Mix_QuerySpec` which queries the default audio device information
 +
 + Returns: a named tuple detailing the default audio device's `frequency`, audio `format`, and `channels`
 + Throws: `dsdl2.SDLException` if failed to query the information
 +/
MixerSpec querySpec() @trusted {
    MixerSpec spec = void;
    if (Mix_QuerySpec(cast(int*)&spec.frequency, cast(ushort*)&spec.format, cast(int*)&spec.channels) != 0) {
        throw new SDLException;
    }

    return spec;
}

static if (sdlMixerSupport >= SDLMixerSupport.v2_6) {
    ubyte getMasterVolume() @trusted {
        return cast(ubyte) Mix_MasterVolume(-1);
    }

    void setMasterVolume(ubyte volume) @trusted {
        Mix_MasterVolume(volume);
    }
}

/++
 + D class that acts as a proxy for a mixer audio channel from a channel ID
 +/
final class Channel {
    const uint mixChannel; /// Channel ID from SDL_mixer

    this() @disable;

    private this(uint mixChannel) {
        this.mixChannel = mixChannel;
    }

    /++
     + Equality operator overload
     +/
    bool opEquals(const Channel rhs) const {
        return this.mixChannel == rhs.mixChannel;
    }

    /++
     + Gets the hash of the `dsdl2.mixer.Channel`
     +
     + Returns: unique hash for the instance being the channel ID
     +/
    override hash_t toHash() const {
        return cast(hash_t) this.mixChannel;
    }

    /++
     + Formats the `dsdl2.mixer.Channel` showing its internal information: `"dsdl2.mixer.Channel(<mixChannel>)"`
     +
     + Returns: the formatted `string`
     +/
    override string toString() const {
        return "dsdl2.mixer.Channel(%d)".format(this.mixChannel);
    }

    void panning(ubyte[2] newLR) const @property @trusted {
        if (Mix_SetPanning(this.mixChannel, newLR[0], newLR[1]) != 0) {
            throw new SDLException;
        }
    }

    static void panning(ubyte[2] newLR) @property @trusted {
        if (Mix_SetPanning(MIX_CHANNEL_POST, newLR[0], newLR[1]) != 0) {
            throw new SDLException;
        }
    }

    void position(Tuple!(short, ubyte) newAngleDistance) const @property @trusted {
        if (Mix_SetPosition(this.mixChannel, newAngleDistance[0], newAngleDistance[1]) != 0) {
            throw new SDLException;
        }
    }

    static void position(Tuple!(short, ubyte) newAngleDistance) @property @trusted {
        if (Mix_SetPosition(MIX_CHANNEL_POST, newAngleDistance[0], newAngleDistance[1]) != 0) {
            throw new SDLException;
        }
    }

    void distance(ubyte newDistance) const @property @trusted {
        if (Mix_SetDistance(this.mixChannel, newDistance) != 0) {
            throw new SDLException;
        }
    }

    static void distance(ubyte newDistance) @property @trusted {
        if (Mix_SetDistance(MIX_CHANNEL_POST, newDistance) != 0) {
            throw new SDLException;
        }
    }

    ubyte volume() const @property @trusted {
        return cast(ubyte) Mix_Volume(this.mixChannel, -1);
    }

    static ubyte volume() @property @trusted {
        return cast(ubyte) Mix_Volume(-1, -1);
    }

    void volume(ubyte newVolume) const @property @trusted {
        Mix_Volume(this.mixChannel, newVolume);
    }

    static void volume(ubyte newVolume) @property @trusted {
        Mix_Volume(-1, newVolume);
    }

    void reverseStereo(bool newReverse) const @property @trusted {
        if (Mix_SetReverseStereo(this.mixChannel, newReverse ? 1 : 0) != 0) {
            throw new SDLException;
        }
    }

    static void reverseStereo(bool newReverse) @property @trusted {
        if (Mix_SetReverseStereo(MIX_CHANNEL_POST, newReverse ? 1 : 0) != 0) {
            throw new SDLException;
        }
    }

    bool paused() const @property @trusted {
        return Mix_Paused(this.mixChannel) == 1;
    }

    bool playing() const @property @trusted {
        return Mix_Playing(this.mixChannel) == 1;
    }

    Fading fading() const @property @trusted {
        return cast(Fading) Mix_FadingChannel(this.mixChannel);
    }

    Chunk chunk() const @property @system {
        return new Chunk(Mix_GetChunk(this.mixChannel), false);
    }

    void play(const Chunk chunk, uint loops = 1, uint ms = cast(uint)-1) const @trusted {
        if (Mix_PlayChannelTimed(this.mixChannel, cast(Mix_Chunk*) chunk.mixChunk, loops, ms) != 0) {
            throw new SDLException;
        }
    }

    static void play(const Chunk chunk, uint loops = 1, uint ms = cast(uint)-1) @trusted {
        if (Mix_PlayChannelTimed(-1, cast(Mix_Chunk*) chunk.mixChunk, loops, ms) != 0) {
            throw new SDLException;
        }
    }

    void fadeIn(const Chunk chunk, uint loops = 1, uint fadeMs = 0, uint ms = cast(uint)-1) const @trusted {
        if (Mix_FadeInChannelTimed(this.mixChannel, cast(Mix_Chunk*) chunk.mixChunk, loops, fadeMs, ms) != 0) {
            throw new SDLException;
        }
    }

    static void fadeIn(const Chunk chunk, uint loops = 1, uint fadeMs = 0, uint ms = cast(uint)-1) @trusted {
        if (Mix_FadeInChannelTimed(-1, cast(Mix_Chunk*) chunk.mixChunk, loops, fadeMs, ms) != 0) {
            throw new SDLException;
        }
    }

    void halt() const @trusted {
        if (Mix_HaltChannel(this.mixChannel) != 0) {
            throw new SDLException;
        }
    }

    static void halt() @trusted {
        if (Mix_HaltChannel(-1) != 0) {
            throw new SDLException;
        }
    }

    void expire(uint ms) const @trusted {
        if (Mix_ExpireChannel(this.mixChannel, ms) != 0) {
            throw new SDLException;
        }
    }

    static void expire(uint ms) @trusted {
        if (Mix_ExpireChannel(-1, ms) != 0) {
            throw new SDLException;
        }
    }

    void fadeOut(uint fadeMs) const @trusted {
        Mix_FadeOutChannel(this.mixChannel, fadeMs);
    }

    static void fadeOut(uint fadeMs) @trusted {
        Mix_FadeOutChannel(-1, fadeMs);
    }

    void pause() const @trusted {
        Mix_Pause(this.mixChannel);
    }

    static void pause() @trusted {
        Mix_Pause(-1);
    }

    void resume() const @trusted {
        Mix_Resume(this.mixChannel);
    }

    static void resume() @trusted {
        Mix_Resume(-1);
    }
}

/++
 + Gets `dsdl2.mixer.Channel` proxy instances of the available audio channels provided by SDL_mixer
 +
 + Returns: array of proxies to the available `dsdl2.mixer.Channel`s
 + Throws: `dsdl2.SDLException` if failed to get the available audio channels
 +/
const(Channel[]) getChannels() @trusted {
    int numChannels = Mix_AllocateChannels(-1);

    static Channel[] channels;
    if (channels !is null) {
        size_t originalLength = channels.length;
        channels.length = numChannels;

        if (numChannels > originalLength) {
            foreach (i; originalLength .. numChannels) {
                channels[i] = new Channel(i.to!uint);
            }
        }
    }
    else {
        channels = new Channel[](numChannels);
        foreach (i; 0 .. numChannels) {
            channels[i] = new Channel(i);
        }
    }

    return channels;
}

final class Chunk {
    private bool isOwner = true;
    private void* userRef = null;

    @system Mix_Chunk* mixChunk = null; /// Internal `Mix_Chunk` pointer

    /++
     + Constructs a `dsdl2.mixer.Chunk` from a vanilla `Mix_Chunk*` from bindbc-sdl
     +
     + Params:
     +   mixChunk = the `Mix_Chunk` pointer to manage
     +   isOwner = whether the instance owns the given `Mix_Chunk*` and should destroy it on its own
     +   userRef = optional pointer to maintain reference link, avoiding GC cleanup
     +/
    this(Mix_Chunk* mixChunk, bool isOwner = true, void* userRef = null) @system
    in {
        assert(mixChunk !is null);
    }
    do {
        this.mixChunk = mixChunk;
        this.isOwner = isOwner;
        this.userRef = userRef;
    }

    ~this() @trusted {
        if (this.isOwner) {
            Mix_FreeChunk(this.mixChunk);
        }
    }

    @trusted invariant {
        // Instance might be in an invalid state due to holding a non-owned externally-freed object when
        // destructed in an unpredictable order.
        if (!this.isOwner && GC.inFinalizer) {
            return;
        }

        assert(this.mixChunk !is null);
    }

    /++
     + Equality operator overload
     +/
    bool opEquals(const Chunk rhs) const @trusted {
        return this.mixChunk is rhs.mixChunk;
    }

    /++
     + Gets the hash of the `dsdl2.mixer.Chunk`
     +
     + Returns: unique hash for the instance being the pointer of the internal `Mix_Chunk` pointer
     +/
    override hash_t toHash() const @trusted {
        return cast(hash_t) this.mixChunk;
    }

    /++
     + Formats the `dsdl2.mixer.Chunk` into its construction representation:
     + `"dsdl2.mixer.Chunk(<mixChunk>)"`
     +
     + Returns: the formatted `string`
     +/
    override string toString() const @trusted {
        return "dsdl2.mixer.Chunk(0x%x)".format(this.mixChunk);
    }

    static string[] decoders() @property @trusted {
        int numDecoders = Mix_GetNumChunkDecoders();
        if (numDecoders <= 0) {
            throw new SDLException;
        }

        static string[] decoders;
        if (decoders !is null) {
            size_t originalLength = decoders.length;
            decoders.length = numDecoders;

            if (numDecoders > originalLength) {
                foreach (i; originalLength .. numDecoders) {
                    decoders[i] = Mix_GetChunkDecoder(i.to!int).to!string.idup;
                }
            }
        }
        else {
            decoders = new string[](numDecoders);
            foreach (i; 0 .. numDecoders) {
                decoders[i] = Mix_GetChunkDecoder(i).to!string.idup;
            }
        }

        return decoders;
    }

    static if (sdlMixerSupport >= SDLMixerSupport.v2_0_2) {
        static bool hasDecoder(string decoder) @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 0, 2));
        }
        do {
            return Mix_HasChunkDecoder(decoder.toStringz()) == SDL_TRUE;
        }
    }

    inout(ubyte[]) buffer() inout @property @trusted {
        return (cast(inout(ubyte*)) this.mixChunk.abuf)[0 .. this.mixChunk.alen];
    }

    ubyte volume() const @property @trusted {
        return cast(ubyte) Mix_VolumeChunk(cast(Mix_Chunk*) this.mixChunk, -1);
    }

    void volume(ubyte newVolume) @property @trusted {
        Mix_VolumeChunk(this.mixChunk, newVolume);
    }
}

Chunk load(string file) @trusted {
    Mix_Chunk* mixChunk = Mix_LoadWAV(file.toStringz());
    if (mixChunk !is null) {
        return new Chunk(mixChunk);
    }
    else {
        throw new SDLException;
    }
}

Chunk loadRaw(const void[] data) @trusted {
    SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
    if (sdlRWops is null) {
        throw new SDLException;
    }

    Mix_Chunk* mixChunk = Mix_LoadWAV_RW(sdlRWops, 1);
    if (mixChunk !is null) {
        return new Chunk(mixChunk);
    }
    else {
        throw new SDLException;
    }
}

Chunk loadPCM(const void[] pcm) @trusted {
    Mix_Chunk* mixChunk = Mix_QuickLoad_RAW(cast(ubyte*) pcm.ptr, pcm.length.to!int);
    if (mixChunk !is null) {
        return new Chunk(mixChunk);
    }
    else {
        throw new SDLException;
    }
}

final class Music {
    private bool isOwner = true;
    private void* userRef = null;

    @system Mix_Music* mixMusic = null; /// Internal `Mix_Music` pointer

    /++
     + Constructs a `dsdl2.mixer.Music` from a vanilla `Mix_Music*` from bindbc-sdl
     +
     + Params:
     +   mixMusic = the `Mix_Music` pointer to manage
     +   isOwner = whether the instance owns the given `Mix_Music*` and should destroy it on its own
     +   userRef = optional pointer to maintain reference link, avoiding GC cleanup
     +/
    this(Mix_Music* mixMusic, bool isOwner = true, void* userRef = null) @system
    in {
        assert(mixMusic !is null);
    }
    do {
        this.mixMusic = mixMusic;
        this.isOwner = isOwner;
        this.userRef = userRef;
    }

    ~this() @trusted {
        if (this.isOwner) {
            Mix_FreeMusic(this.mixMusic);
        }
    }

    @trusted invariant {
        // Instance might be in an invalid state due to holding a non-owned externally-freed object when
        // destructed in an unpredictable order.
        if (!this.isOwner && GC.inFinalizer) {
            return;
        }

        assert(this.mixMusic !is null);
    }

    /++
     + Equality operator overload
     +/
    bool opEquals(const Music rhs) const @trusted {
        return this.mixMusic is rhs.mixMusic;
    }

    /++
     + Gets the hash of the `dsdl2.mixer.Music`
     +
     + Returns: unique hash for the instance being the pointer of the internal `Mix_Music` pointer
     +/
    override hash_t toHash() const @trusted {
        return cast(hash_t) this.mixMusic;
    }

    /++
     + Formats the `dsdl2.mixer.Music` into its construction representation:
     + `"dsdl2.mixer.Music(<mixMusic>)"`
     +
     + Returns: the formatted `string`
     +/
    override string toString() const @trusted {
        return "dsdl2.mixer.Music(0x%x)".format(this.mixMusic);
    }

    static string[] decoders() @property @trusted {
        int numDecoders = Mix_GetNumMusicDecoders();
        if (numDecoders <= 0) {
            throw new SDLException;
        }

        static string[] decoders;
        if (decoders !is null) {
            size_t originalLength = decoders.length;
            decoders.length = numDecoders;

            if (numDecoders > originalLength) {
                foreach (i; originalLength .. numDecoders) {
                    decoders[i] = Mix_GetMusicDecoder(i.to!int).to!string.idup;
                }
            }
        }
        else {
            decoders = new string[](numDecoders);
            foreach (i; 0 .. numDecoders) {
                decoders[i] = Mix_GetMusicDecoder(i).to!string.idup;
            }
        }

        return decoders;
    }

    static if (sdlMixerSupport >= SDLMixerSupport.v2_6) {
        static bool hasDecoder(string decoder) @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_HasMusicDecoder(decoder.toStringz()) == SDL_TRUE;
        }
    }

    MusicType type() const @property @trusted {
        return cast(MusicType) Mix_GetMusicType(this.mixMusic);
    }

    static if (sdlMixerSupport >= SDLMixerSupport.v2_6) {
        string title() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_GetMusicTitle(this.mixMusic).to!string.idup;
        }

        string titleTag() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_GetMusicTitleTag(this.mixMusic).to!string.idup;
        }

        string artistTag() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_GetMusicArtistTag(this.mixMusic).to!string.idup;
        }

        string albumTag() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_GetMusicAlbumTag(this.mixMusic).to!string.idup;
        }

        string copyrightTag() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_GetMusicCopyrightTag(this.mixMusic).to!string.idup;
        }

        ubyte volume() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return cast(ubyte) Mix_GetMusicVolume(cast(Mix_Music*) this.mixMusic);
        }

        double position() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_GetMusicPosition(cast(Mix_Music*) this.mixMusic);
        }

        double duration() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_MusicDuration(cast(Mix_Music*) this.mixMusic);
        }

        double loopStartTime() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_GetMusicLoopStartTime(cast(Mix_Music*) this.mixMusic);
        }

        double loopEndTime() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_GetMusicLoopEndTime(cast(Mix_Music*) this.mixMusic);
        }

        double loopLengthTime() const @property @trusted
        in {
            assert(dsdl2.mixer.getVersion() >= Version(2, 6));
        }
        do {
            return Mix_GetMusicLoopLengthTime(cast(Mix_Music*) this.mixMusic);
        }
    }

    static void position(ubyte newPosition) @property @trusted {
        if (Mix_SetMusicPosition(newPosition) != 0) {
            throw new SDLException;
        }
    }

    static ubyte volume() @property @trusted {
        return cast(ubyte) Mix_VolumeMusic(-1);
    }

    static void volume(ubyte newVolume) @property @trusted {
        Mix_VolumeMusic(newVolume);
    }

    static bool paused() @trusted {
        return Mix_PausedMusic() == 1;
    }

    static bool playing() @trusted {
        return Mix_PlayingMusic() == 1;
    }

    static Fading fading() @property @trusted {
        return cast(Fading) Mix_FadingMusic();
    }

    static void command(string newCommand) @property @trusted {
        if (Mix_SetMusicCMD(newCommand.toStringz()) != 0) {
            throw new SDLException;
        }
    }

    void play(uint loops = 1) const @trusted {
        if (Mix_PlayMusic(cast(Mix_Music*) this.mixMusic, loops.to!int) != 0) {
            throw new SDLException;
        }
    }

    void fadeIn(uint loops = 1, uint ms = 0, double position = 0) const @trusted {
        if (Mix_FadeInMusicPos(cast(Mix_Music*) this.mixMusic, loops, ms, position) != 0) {
            throw new SDLException;
        }
    }

    static void fadeOut(uint ms) @trusted {
        Mix_FadeOutMusic(ms.to!int);
    }

    static void halt() @trusted {
        Mix_HaltMusic();
    }

    static void pause() @trusted {
        Mix_PauseMusic();
    }

    static void resume() @trusted {
        Mix_ResumeMusic();
    }

    static void rewind() @trusted {
        Mix_RewindMusic();
    }
}

Music loadMusic(string file) @trusted {
    Mix_Music* mixMusic = Mix_LoadMUS(file.toStringz());
    if (mixMusic !is null) {
        return new Music(mixMusic);
    }
    else {
        throw new SDLException;
    }
}

Music loadMusicRaw(const void[] data) @trusted {
    SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
    if (sdlRWops is null) {
        throw new SDLException;
    }

    Mix_Music* mixMusic = Mix_LoadMUS_RW(sdlRWops, 1);
    if (mixMusic !is null) {
        return new Music(mixMusic);
    }
    else {
        throw new SDLException;
    }
}

Music loadMusicRaw(const void[] data, MusicType type) @trusted {
    SDL_RWops* sdlRWops = SDL_RWFromConstMem(data.ptr, data.length.to!int);
    if (sdlRWops is null) {
        throw new SDLException;
    }

    Mix_Music* mixMusic = Mix_LoadMUSType_RW(sdlRWops, type, 1);
    if (mixMusic !is null) {
        return new Music(mixMusic);
    }
    else {
        throw new SDLException;
    }
}
