BEGIN {
    FS = "\t"
    OFS = "\t"
    template_count = 0
    
    # Store second argument but don't read it automatically
    intensity_file = ARGV[2]
    ARGV[2] = ""
}

# First file (template BED) - read into memory
{
    if (NF < 6) {
        print "Incomplete line at template line " FNR > "/dev/stderr"
        exit 1
    }
    template_count++
    template_chr[template_count] = $1
    template_start[template_count] = $2 + 0
    template_stop[template_count] = $3 + 0
    template_strand[template_count] = $6
}

END {
    # Read intensities directly
    
    print "Loaded " template_count " template intervals" > "/dev/stderr"
    print "Start processing intensities..." > "/dev/stderr"
    print "Intensities file: " intensity_file > "/dev/stderr"
    
    current_group = ""
    through_pos = 0
    
    for (i = 1; i <= template_count; i++) {
        chr = template_chr[i]
        start = template_start[i]
        stop = template_stop[i]
        strand = template_strand[i]
        
        for (pos = start; pos < stop; pos++) {
            if ((getline intensity_line < intensity_file) <= 0) {
                print "Not enough intensity values (need " (through_pos + 1) ", got " through_pos ")" > "/dev/stderr"
                close(intensity_file)
                exit 1
            }
            intensity = intensity_line + 0
            
            # Check if can merge with current group
            if (current_group != "" && \
                current_chr == chr && \
                current_strand == strand && \
                current_intensity == intensity && \
                current_stop == pos) {
                current_stop = pos + 1
            } else {
                # Output previous group
                if (current_group != "") {
                    print current_chr, current_start, current_stop, ".", current_intensity, current_strand
                }
                # Start new group
                current_group = 1
                current_chr = chr
                current_start = pos
                current_stop = pos + 1
                current_strand = strand
                current_intensity = intensity
            }
            
            through_pos++
            # Progress every 10M positions
            if (through_pos % 10000000 == 0) {
                print "Processed " through_pos " positions..." > "/dev/stderr"
            }
        }
    }
    
    # Output last group
    if (current_group != "") {
        print current_chr, current_start, current_stop, ".", current_intensity, current_strand
    }
    
    close(intensity_file)
    print "Done. Total positions: " through_pos > "/dev/stderr"
}
