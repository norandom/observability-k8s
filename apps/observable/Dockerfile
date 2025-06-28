FROM continuumio/miniconda3:latest

# Set working directory
WORKDIR /app

# Copy conda environment file
COPY conda-environment.yml /tmp/environment.yml

# Create conda environment
RUN conda env create -f /tmp/environment.yml && \
    conda clean -afy

# Activate conda environment and install Observable Framework
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate observable-dashboard && \
    npm install -g @observablehq/framework@latest

# Verify installations
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate observable-dashboard && \
    python --version && \
    node --version && \
    npm --version && \
    python -c "import polars, pandas, requests; print('Python packages OK')" && \
    npx @observablehq/framework --version

# Create app structure and copy dashboard files
RUN mkdir -p /app/src/data

# Copy dashboard source files into the container
COPY src/ /app/src/

# Initialize npm project with proper start script
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate observable-dashboard && \
    npm init -y && \
    npm install @observablehq/framework && \
    npm pkg set scripts.start="npx @observablehq/framework dev --host 0.0.0.0 --port 3000"

# Set environment variables
ENV CONDA_DEFAULT_ENV=observable-dashboard
ENV PATH=/opt/conda/envs/observable-dashboard/bin:$PATH
ENV LOKI_ENDPOINT=http://192.168.122.27:3100
ENV QUICKWIT_ENDPOINT=http://192.168.122.27:7280
ENV PROMETHEUS_ENDPOINT=http://192.168.122.27:9090

# Expose port
EXPOSE 3000

# Use conda environment for all commands
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "observable-dashboard"]
CMD ["npm", "start"]