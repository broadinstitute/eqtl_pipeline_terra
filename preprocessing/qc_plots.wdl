task cells_per_donor {
    
    File counts
    File cell_donor_map
    String png_name

    command {
        set -euo pipefail
        python /src/cells_per_donor.py ${counts} ${cell_donor_map} ${png_name}
    }

    runtime {
        docker: "gcr.io/broad-cga-francois-gtex/gtex_eqtl:V9"
    }

    output {
        File cell_donor_png="${png_name}.cells_per_donor.png"
    }

}
