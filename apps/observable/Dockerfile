FROM continuumio/miniconda3:latest

# Set working directory
WORKDIR /app

# Copy conda environment file
COPY conda-environment.yml /tmp/environment.yml

# Create conda environment
RUN conda env create -f /tmp/environment.yml && \
    conda clean -afy

# Make RUN commands use the new environment
SHELL ["conda", "run", "-n", "observable-dashboard", "/bin/bash", "-c"]

# Install Observable Framework via npm (must be done after conda environment is activated)
RUN npm install -g @observablehq/framework@latest

# Verify installations
RUN python --version && \
    node --version && \
    npm --version && \
    python -c "import polars, pandas, requests; print('Python packages OK')" && \
    npx @observablehq/framework --version

# Create app structure
RUN mkdir -p /app/src/data

# Set environment variables
ENV CONDA_DEFAULT_ENV=observable-dashboard
ENV PATH=/opt/conda/envs/observable-dashboard/bin:$PATH

# Expose port
EXPOSE 3000

# Use conda environment for all commands
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "observable-dashboard"]
CMD ["/bin/bash", "/config/start.sh"]