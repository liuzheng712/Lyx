/**
 * \file AppleSpeller.m
 * This file is part of LyX, the document processor.
 * Licence details can be found in the file COPYING.
 *
 * \author Stephan Witt
 *
 * Full author contact details are available in file CREDITS.
 */

#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

#import <AvailabilityMacros.h>

#include "support/AppleSpeller.h"

typedef struct AppleSpellerRec {
	NSSpellChecker * checker;
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && (__MAC_OS_X_VERSION_MAX_ALLOWED >= 1050)
	NSInteger doctag;
#else
	int doctag;
#endif
	NSArray * suggestions;
	NSArray * misspelled;
} AppleSpellerRec ;


AppleSpeller newAppleSpeller(void)
{
	AppleSpeller speller = calloc(1, sizeof(AppleSpellerRec));
	speller->checker = [NSSpellChecker sharedSpellChecker];
	speller->doctag = [NSSpellChecker uniqueSpellDocumentTag];
	speller->suggestions = nil;
	speller->misspelled = nil;
	return speller;
}


void freeAppleSpeller(AppleSpeller speller)
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	[speller->checker closeSpellDocumentWithTag:speller->doctag];

	[speller->suggestions release];
	[speller->misspelled release];

	[pool release];

	free(speller);
}


static NSString * toString(const char * word)
{
	return [[NSString alloc] initWithBytes:word length:strlen(word) encoding:NSUTF8StringEncoding];
}


static NSString * toLanguage(AppleSpeller speller, const char * lang)
{
	NSString * result = nil;
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && (__MAC_OS_X_VERSION_MAX_ALLOWED >= 1050)
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * lang_ = toString(lang);
	if ([NSSpellChecker instancesRespondToSelector:@selector(availableLanguages)]) {
		NSArray * languages = [speller->checker availableLanguages];
		
		for (NSString *element in languages) {
			if ([element isEqualToString:lang_]) {
				result = element;
				break;
			} else if ([lang_ hasPrefix:element]) {
				result = element;
			}
		}
	}
	[lang_ release];
	[pool release];
#endif
	return result;
}


SpellCheckResult checkAppleSpeller(AppleSpeller speller, const char * word, const char * lang)
{
	if (!speller->checker || !lang || !word)
		return SPELL_CHECK_FAILED;

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * word_ = toString(word);
	NSString * lang_ = toString(lang);
	SpellCheckResult result = SPELL_CHECK_FAILED;
	int start = 0;

	[speller->misspelled release];
	speller->misspelled = nil;

	while (result == SPELL_CHECK_FAILED) {
		NSRange match = [speller->checker
			checkSpellingOfString:word_
			startingAt:start
			language:lang_
			wrap:NO
			inSpellDocumentWithTag:speller->doctag
			wordCount:NULL];

		result = match.length == 0 ? SPELL_CHECK_OK : SPELL_CHECK_FAILED;
		if (result == SPELL_CHECK_OK) {
			if ([NSSpellChecker instancesRespondToSelector:@selector(hasLearnedWord:)]) {
				if ([speller->checker hasLearnedWord:word_])
					result = SPELL_CHECK_LEARNED;
			}
		} else {
			int capacity = [speller->misspelled count] + 1;
			NSMutableArray * misspelled = [NSMutableArray arrayWithCapacity:capacity];
			[misspelled addObjectsFromArray:speller->misspelled];
			[misspelled addObject:[NSValue valueWithRange:match]];
			[speller->misspelled release];
			speller->misspelled = [[NSArray arrayWithArray:misspelled] retain];
			start = match.location + match.length + 1;
		}
	}

	[word_ release];
	[lang_ release];
	[pool release];

	return [speller->misspelled count] ? SPELL_CHECK_FAILED : result;
}


void ignoreAppleSpeller(AppleSpeller speller, const char * word)
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * word_ = toString(word);

	[speller->checker ignoreWord:word_ inSpellDocumentWithTag:(speller->doctag)];

	[word_ release];
	[pool release];
}


size_t makeSuggestionAppleSpeller(AppleSpeller speller, const char * word, const char * lang)
{
	if (!speller->checker || !word || !lang)
		return 0;

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * word_ = toString(word);
	NSString * lang_ = toString(lang);
	NSArray * result ;

#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && (__MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
	// Mac OS X 10.6 only
	NSInteger slen = [word_ length];
	NSRange range = { 0, slen };
	
	if ([NSSpellChecker instancesRespondToSelector:@selector(guessesForWordRange:)]) {
		result = [speller->checker guessesForWordRange:range
			inString:word_
			language:lang_
			inSpellDocumentWithTag:speller->doctag];
	} else {
		[speller->checker setLanguage:lang_];
		result = [speller->checker guessesForWord:word_];
	}
#else
	[speller->checker setLanguage:lang_];
	result = [speller->checker guessesForWord:word_];
#endif

	[word_ release];
	[lang_ release];

	[speller->suggestions release];
	speller->suggestions = [[NSArray arrayWithArray:result] retain];

	[pool release];
	return [speller->suggestions count];
}


const char * getSuggestionAppleSpeller(AppleSpeller speller, size_t pos)
{
	const char * result = 0;
	if (pos < [speller->suggestions count]) {
		result = [[speller->suggestions objectAtIndex:pos] UTF8String] ;
	}
	return result;
}


void learnAppleSpeller(AppleSpeller speller, const char * word)
{
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && (__MAC_OS_X_VERSION_MAX_ALLOWED >= 1050)
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * word_ = toString(word);

	if ([NSSpellChecker instancesRespondToSelector:@selector(learnWord:)])
		[speller->checker learnWord:word_];
	
	[word_ release];
	[pool release];
#endif
}


void unlearnAppleSpeller(AppleSpeller speller, const char * word)
{
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && (__MAC_OS_X_VERSION_MAX_ALLOWED >= 1050)
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * word_ = toString(word);

	if ([NSSpellChecker instancesRespondToSelector:@selector(unlearnWord:)])
		[speller->checker unlearnWord:word_];
	
	[word_ release];
	[pool release];
#endif
}


int numMisspelledWordsAppleSpeller(AppleSpeller speller)
{
	return [speller->misspelled count];
}


void misspelledWordAppleSpeller(AppleSpeller speller, int const position, int * start, int * length)
{
	NSRange range = [[speller->misspelled objectAtIndex:position] rangeValue];
	*start = range.location;
	*length = range.length;
}


int hasLanguageAppleSpeller(AppleSpeller speller, const char * lang)
{
	return toLanguage(speller, lang) != nil;
}