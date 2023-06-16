/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org/, MIT License)
 +/

module dsdl2.clipboard;
@safe:

import bindbc.sdl;
import dsdl2.sdl;

import core.stdc.string;
import std.conv : to;
import std.string : toStringz;

/++ 
 + Wraps `SDL_GetClipboardText` which gets the text stored in the clipboard
 + 
 + Throws: `dsdl2.SDLException` if the clipboard text failed to allocate on SDL's side
 + 
 + Returns: clipboard text content
 +/
string getClipboard() @trusted {
    char* clipboard = SDL_GetClipboardText();
    scope (exit)
        SDL_free(clipboard);

    if (clipboard != null && strlen(clipboard) > 0) {
        return clipboard.to!string.idup;
    }
    else {
        throw new SDLException;
    }
}

/++ 
 + Wraps `SDL_HasClipboardText` which checks whether the clipboard exists and contains a non-empty text string
 + 
 + Returns: `true` if it exists and contains a non-empty string, otherwise `false`
 +/
bool hasClipboard() @trusted {
    return SDL_HasClipboardText() == SDL_TRUE;
}

/++ 
 + Wraps `SDL_SetClipboardText` which puts a string of text into the clipboard
 + 
 + Params:
 +   text = `string` to put into the clipboard
 + 
 + Throws: `dsdl2.SDLException` on fail when putting the string into the clipboard
 +/
void setClipboard(string text) @trusted {
    if (SDL_SetClipboardText(text.toStringz()) != 0) {
        throw new SDLException;
    }
}

static if (sdlSupport >= SDLSupport.v2_26) {
    /++ 
     + Wraps `SDL_GetPrimarySelectionText` which gets the text stored in the primary selection
     + 
     + Throws: `dsdl2.SDLException` if the primary selection text failed to allocate on SDL's side
     + 
     + Returns: primary selection text content
     +/
    string getPrimarySelectionText() @trusted
    in {
        assert(getVersion() >= Version(2, 26, 0));
    }
    do {
        char* primarySelection = SDL_GetPrimarySelectionText();
        scope (exit)
            SDL_free(primarySelection);

        if (primarySelection != null && strlen(primarySelection) > 0) {
            return primarySelection.to!string.idup;
        }
        else {
            throw new SDLException;
        }
    }

    /++ 
     + Wraps `SDL_HasPrimarySelectionText` which checks whether the primary selection exists and contains a
     + non-empty text string
     + 
     + Returns: `true` if it exists and contains a non-empty string, otherwise `false`
     +/
    bool hasPrimarySelection() @trusted
    in {
        assert(getVersion() >= Version(2, 26, 0));
    }
    do {
        return SDL_HasPrimarySelectionText() == SDL_TRUE;
    }

    /++ 
     + Wraps `SDL_SetPrimarySelectionText` which puts a string of text into the primary selection
     + 
     + Params:
     +   text = `string` to put into the primary selection
     + 
    + Throws: `dsdl2.SDLException` on fail when putting the string into the primary selection
     +/
    void setPrimarySelection(string text) @trusted
    in {
        assert(getVersion() >= Version(2, 26, 0));
    }
    do {
        if (SDL_SetPrimarySelectionText(text.toStringz()) != 0) {
            throw new SDLException;
        }
    }
}
