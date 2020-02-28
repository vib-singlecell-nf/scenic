nextflow.preview.dsl=2

binDir = !params.containsKey("test") ? "${workflow.projectDir}/src/scenic/bin/" : ""

toolParams = params.sc.scenic
processParams = params.sc.scenic.grn

process ARBORETO_WITH_MULTIPROCESSING {

    // Process will be submitted as job if toolParams.labels.processExecutor = 'qsub' (default)
    label "${processParams.labels ? processParams.labels.processExecutor : "local"}"
    cache 'deep'
    container toolParams.container
    publishDir "${toolParams.scenicoutdir}/${sampleId}/arboreto_with_multiprocessing/${"numRuns" in toolParams && toolParams.numRuns > 1 ? "run_" + runId : ""}", mode: 'link', overwrite: true
    clusterOptions "-l nodes=1:ppn=${processParams.numWorkers} -l pmem=${processParams.pmem} -l walltime=${processParams.walltime} -A ${params.global.qsubaccount}"
    maxForks processParams.maxForks

    input:
        tuple \
            val(sampleId), \
            path(filteredLoom), \
            val(runId)
        file tfs

    output:
        tuple val(sampleId), \
        file(filteredLoom), \
        file("${outputFileName}"), \
        val(runId)

    script:
        if(!processParams.containsKey("numWorkers"))
            throw new Exception("numWorkers is missing in params.sc.scenic.aucell")
        if(processParams.labels && processParams.labels.processExecutor == 'qsub') {
            if(!processParams.containsKey("pmem"))
                throw new Exception("pmem is missing in params.sc.scenic.aucell")
            if(!processParams.containsKey("walltime"))
                throw new Exception("walltime is missing in params.sc.scenic.aucell")
        }
        outputFileName = "numRuns" in toolParams && toolParams.numRuns > 1 ? sampleId + "__run_" + runId +"__adj.tsv" : sampleId + "__adj.tsv"
        seed = "numRuns" in toolParams && toolParams.numRuns > 1 ? (params.seed + runId) : params.seed
        """
        ${binDir}arboreto_with_multiprocessing.py \
            $filteredLoom \
            $tfs \
            --output ${outputFileName} \
            --num_workers ${processParams.numWorkers} \
            --cell_id_attribute ${toolParams.cell_id_attribute} \
            --gene_attribute ${toolParams.gene_attribute} \
            --method ${processParams.algorithm} \
            --seed ${seed}
        """

}

/* options to implement:
flag parameters not yet implemented:
        --transpose
*/