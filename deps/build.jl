import Conda
Conda.add_channel("conda-forge")
Conda.add("adaptive")

import Pkg
ENV["PYTHON"] = ""
Pkg.build("PyCall")

