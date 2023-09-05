//
// This file holds several functions specific to the workflow/esga.nf in the nf-core/esga pipeline
//

class WorkflowPipeline {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {


        if (!params.run_name) {
            log.info  "Must provide a run_name (--run_name)"
            System.exit(1)
        }
    
        if (!params.fasta || !params.samples) {
            log.info "Missing mandatory options --fasta and/or --samples"
            System.exit(1)
        }

    }

}
