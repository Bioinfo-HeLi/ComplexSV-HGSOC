chromthripsis_high_conf <- function(chromothripsis_chromSummary, pvalue_threshold){
  p1 <- chromothripsis_chromSummary$pval_fragment_joins
  p2 <- chromothripsis_chromSummary$chr_breakpoint_enrichment
  p3 <- chromothripsis_chromSummary$pval_exp_cluster
  high_confidence_index1 <- which(chromothripsis_chromSummary$number_DEL + chromothripsis_chromSummary$number_DUP + chromothripsis_chromSummary$number_h2hINV + chromothripsis_chromSummary$number_t2tINV >= 6 &
                                    chromothripsis_chromSummary$max_number_oscillating_CN_segments_2_states >=7 &
                                    p1 <= pvalue_threshold &
                                    ((p2 <= pvalue_threshold & is.na(p3))|
                                       (is.na(p2) & p3 <= pvalue_threshold)|
                                       (p2 <= pvalue_threshold | p3 <= pvalue_threshold)))
  
  high_confidence_index2 <- which(chromothripsis_chromSummary$number_DEL + chromothripsis_chromSummary$number_DUP + chromothripsis_chromSummary$number_h2hINV + chromothripsis_chromSummary$number_t2tINV >= 3 &
                                    chromothripsis_chromSummary$number_TRA >=4 &
                                    chromothripsis_chromSummary$max_number_oscillating_CN_segments_2_states >=7 &
                                    p1 <= pvalue_threshold)
  
  low_confidence_index <- which(chromothripsis_chromSummary$number_DEL + chromothripsis_chromSummary$number_DUP + chromothripsis_chromSummary$number_h2hINV + chromothripsis_chromSummary$number_t2tINV >= 6 &
                                  chromothripsis_chromSummary$max_number_oscillating_CN_segments_2_states %in% c(4,5,6) &
                                  p1 <= pvalue_threshold &
                                  ((p2 <= pvalue_threshold & is.na(p3))|
                                     (is.na(p2) & p3 <= pvalue_threshold)|
                                     (p2 <= pvalue_threshold | p3 <= pvalue_threshold)))
  return(list(high_confidence_index1, high_confidence_index2, low_confidence_index))
}







