# For now this is just some sample code showing what I want the api to look like.

timer = FixedTempo(220)
synth = FilterSaw(...synth params...)

# Pattern builds a list of notes with pitches, start times and durations in beats, as well
# as any other parameters that should be passed to the synth.
p = Pattern(1/2)

# relative times with rest at beginning of bar
p.add('_ Ab3 Eb4 G4 C5', [1, 2, 1, 2, 2], [0, .5, .5, 2, .5])
p.add('Eb5 C5 G4 F4 G4 C5', [1, 1, 2, 1, 1, 2], [.8, .8, 1.5, .8, .8, 1.5])

# This would return a function of no arguments that returns a signal.
signaldef = play_synth(synth, pattern, timer)

