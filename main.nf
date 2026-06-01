#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.data_dir = params.data_dir ?: 'data'
params.raw_dir = params.raw_dir ?: 'hipstr/raw'
params.split_dir = params.split_dir ?: 'hipstr/split'
params.merge_dir = params.merge_dir ?: 'hipstr/merged'
params.dumpstr_dir = params.dumpstr_dir ?: 'hipstr/dumpstr'
params.correct_dir = params.correct_dir ?: 'hipstr/correct'
params.df_dir = params.df_dir ?: 'hipstr/df_str'
params.log_dir = params.log_dir ?: 'logs'

params.ref = params.ref ?: 'ref/GRCh38_full_analysis_set_plus_decoy_hla.fa'
params.regions = params.regions ?: 'ref/hg38.hipstr_reference.bed'
params.segdup = params.segdup ?: 'sample/hg38_segdup.sorted.bed.gz'
params.cram_download_list = params.cram_download_list ?: 'sample/cram_download.txt'
params.cram_list = params.cram_list ?: 'sample/cram.txt'
params.left_cram_list = params.left_cram_list ?: 'sample/left_cram.txt'
params.filtered_vcf_list = params.filtered_vcf_list ?: 'sample/filtered_vcf.txt'
params.correct_vcf_list = params.correct_vcf_list ?: 'sample/correct_vcf.txt'
params.chrs_list = params.chrs_list ?: 'processed/chrs.txt'
params.hipstr_bin = params.hipstr_bin ?: '/cfs/earth/scratch/xiaf/hgdp/HipSTR/HipSTR'
params.mergeSTR = params.mergeSTR ?: '/cfs/earth/scratch/xiaf/bin/mergeSTR/bin/mergeSTR'
params.dumpSTR = params.dumpSTR ?: '/cfs/earth/scratch/xiaf/bin/STRTools/strtools_venv/bin/dumpSTR'
params.correction_script = params.correction_script ?: 'hipstr_correction.py'
params.vcf_to_matrix = params.vcf_to_matrix ?: 'hipstr_vcf.py'
params.samtools = params.samtools ?: 'samtools'
params.bcftools = params.bcftools ?: 'bcftools'
params.tabix = params.tabix ?: 'tabix'
params.num_files = params.num_files ?: 40

workflow {
    download_done = downloadBams()
    crai_done = checkCrai(download_done)
    hipstr_done = runHipSTR(crai_done)
    split_done = splitVCFs(hipstr_done)
    merged_done = mergeVCFs(split_done)
    filtered_done = filterVCFs(merged_done)
    corrected_done = correctVCFs(filtered_done)
    matrix_done = convertVCFs(corrected_done)

    emit:
    corrected_done, matrix_done
}

process downloadBams {
    tag 'download'

    output:
    path 'download.done'

    script:
    """
    mkdir -p ${params.data_dir}
    echo "Download started: $(date)" > ${params.data_dir}/download.log
    count=0
    while IFS= read -r url; do
        if [ "$count" -ge ${params.num_files} ]; then
            break
        fi
        filename=$(basename "$url")
        file_path="${params.data_dir}/$filename"
        if [ -f "$file_path" ]; then
            echo "[SKIPPED] File $count: $filename already exists, skipping." | tee -a ${params.data_dir}/download.log
        else
            echo "Downloading file $count: $url ..." | tee -a ${params.data_dir}/download.log
            wget -q -P ${params.data_dir} "$url"
            wget -q -P ${params.data_dir} "${url}.crai"
            if [ $? -eq 0 ]; then
                echo "[SUCCESS] File $count: $filename downloaded." | tee -a ${params.data_dir}/download.log
            else
                echo "[ERROR] File $count: $filename failed to download." | tee -a ${params.data_dir}/download.log
            fi
        fi
        count=$((count + 1))
    done < ${params.cram_download_list}
    touch download.done
    """
}

process checkCrai {
    tag 'crai_check'
    input:
    path done

    output:
    path 'crai_check.done'

    script:
    """
    mkdir -p ${params.data_dir}
    while IFS= read -r SAMPLE; do
        CRAM="${params.data_dir}/${SAMPLE}"
        CRAI="${CRAM}.crai"
        if [[ ! -f "$CRAM" ]]; then
            echo "MISSING: $CRAM"
            continue
        fi
        echo "Checking index for $CRAM"
        ${params.samtools} index "$CRAM" -o "$CRAI"
    done < ${params.left_cram_list}
    touch crai_check.done
    """
}

process runHipSTR {
    tag 'hipstr'

    input:
    path done

    output:
    path 'hipstr.done'

    script:
    """
    mkdir -p ${params.raw_dir}
    while IFS= read -r sample; do
        sample_base=$(basename "$sample" .cram)
        if [ ! -f "${params.data_dir}/${sample}" ]; then
            echo "ERROR: CRAM file ${params.data_dir}/${sample} not found!" >&2
            exit 1
        fi
        if [ -f "${params.raw_dir}/${sample_base}.hipstr.vcf.gz" ]; then
            echo "INFO: Output for ${sample_base} already exists. Skipping."
            continue
        fi

        ${params.hipstr_bin} \
            --bams ${params.data_dir}/${sample} \
            --fasta ${params.ref} \
            --regions ${params.regions} \
            --str-vcf ${params.raw_dir}/${sample_base}.hipstr.vcf.gz \
            --log ${params.raw_dir}/${sample_base}.hipstr.log \
            --min-reads 5 \
            --max-reads 2000000
    done < ${params.cram_list}
    touch hipstr.done
    """
}

process splitVCFs {
    tag 'split'
    input:
    path done

    output:
    path 'split.done'

    script:
    """
    mkdir -p ${params.split_dir}
    for vcf in ${params.raw_dir}/*.vcf.gz; do
        sample=$(basename "$vcf" .hipstr.vcf.gz)
        ${params.tabix} -p vcf "$vcf"
        for chr in $(seq 1 22); do
            chr_name="chr${chr}"
            out_vcf="${params.split_dir}/${sample}_${chr_name}.vcf.gz"
            ${params.bcftools} view -r "$chr_name" -Oz -o "$out_vcf" "$vcf"
            ${params.tabix} -p vcf "$out_vcf"
        done
    done
    touch split.done
    """
}

process mergeVCFs {
    tag 'merge'
    input:
    path done

    output:
    path 'merge.done'

    script:
    """
    mkdir -p ${params.merge_dir}
    while IFS= read -r CHR_NAME; do
        vcfs=$(ls ${params.split_dir}/*_${CHR_NAME}.vcf.gz | paste -sd, -)
        ${params.mergeSTR} --vcfs "$vcfs" --vcftype hipstr --out ${params.merge_dir}/merged_${CHR_NAME}
    done < ${params.chrs_list}
    touch merge.done
    """
}

process filterVCFs {
    tag 'filter'
    input:
    path done

    output:
    path 'filter.done'

    script:
    """
    mkdir -p ${params.dumpstr_dir}
    while IFS= read -r CHR_NAME; do
        vcfs=${params.merge_dir}/merged_${CHR_NAME}.vcf
        out=${params.dumpstr_dir}/${CHR_NAME}_filtered
        echo "Filtering ${vcfs}"
        ${params.dumpSTR} --vcf "$vcfs" \
            --vcftype hipstr \
            --out "$out" \
            --min-locus-callrate 0.80 \
            --min-locus-hwep 0.000001 \
            --filter-regions ${params.segdup} \
            --filter-regions-names SEGDUP \
            --zip \
            --drop-filtered
    done < ${params.chrs_list}
    touch filter.done
    """
}

process correctVCFs {
    tag 'correct'
    input:
    path done

    output:
    path 'correct.done'

    script:
    """
    mkdir -p ${params.correct_dir}
    while IFS= read -r VCF_NAME; do
        vcf=${params.dumpstr_dir}/${VCF_NAME}
        basename=$(basename "$VCF_NAME" .gz)
        python ${params.correction_script} "$vcf" "${params.correct_dir}/${basename}"
    done < ${params.filtered_vcf_list}
    touch correct.done
    """
}

process convertVCFs {
    tag 'convert'
    input:
    path done

    output:
    path 'convert.done'

    script:
    """
    mkdir -p ${params.df_dir}
    while IFS= read -r VCF_NAME; do
        vcf=${params.correct_dir}/${VCF_NAME}
        python ${params.vcf_to_matrix} -i "$vcf" -o "${params.df_dir}/"
    done < ${params.correct_vcf_list}
    touch convert.done
    """
}
