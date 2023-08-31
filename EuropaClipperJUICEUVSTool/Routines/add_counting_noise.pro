pro add_counting_noise, detector_counts, detector_counts_noise

detector_counts_noise = POIDEV(detector_counts[*,*,*], SEED = seed) ; (Counts/s)'

end