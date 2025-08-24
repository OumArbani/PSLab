# Contributing to PS Lab

First off, thank you for considering contributing to PS Lab! 🎉 We are thrilled that you're interested in helping make the PS Lab tool better for the entire Salesforce community. Every contribution, from a small typo fix to a new feature, is valuable.

This document provides guidelines for contributing to the project. Please read it to ensure a smooth and effective collaboration process.

## How Can I Contribute?

There are many ways to contribute to the project, and not all of them involve writing code.

### Reporting Bugs
If you find a bug, please open an issue and provide as much detail as possible. Following the Bug Report Template will help us resolve it faster.

### Suggesting Enhancements
Have an idea for a new feature or an improvement to an existing one? Open an issue to start a discussion.We'd love to hear your thoughts! Please use the Enhancement Request Template.

### Submitting Pull Requests
If you're ready to write some code, you can pick up an existing issue, or submit a PR for a bug fix or enhancement you've developed.

## Development Setup

To get started with the code, you'll need to set up a local development environment.

### Fork & Clone the Repository
1. First, fork the main PS Lab repository to your own GitHub account.
2. Then, clone your forked repository to your local machine:

```bash
git clone https://github.com/OumArbani/PSLab.git
cd pslab
```

### Install Salesforce CLI
Ensure you have the latest version of the Salesforce CLI installed and that it's connected to your Dev environment.

### Authorize Your Org
We recommend using a dedicated Developer Edition org or a Scratch Org for development. Authorize your target org:

```bash
# For a Developer Edition or Sandbox
sf org login web --alias pslab-dev

# Or create a scratch org (if a project-scratch-def.json is available)
sf org create scratch --definition-file config/project-scratch-def.json --alias pslab-scratch --set-default
```
### Deploy the Source Code
Push the entire project to your development org

### Assign Permissions
Assign the **`PSLabUser`** permission set to your user to ensure you have access to all components:

```bash
sf org assign permset --name PSLabUser --target-org pslab-dev
```

You are now ready to start developing!

## Pull Request Process

1. Create a new branch from main in your forked repository. Use a descriptive branch name (e.g., feature/add-csv-export or fix/tooltip-bug). 
2. Make your code changes. Ensure your code adheres to the project's coding conventions. 
3. If you've added new functionality, please add or update relevant tests. 
4. Commit your changes with a clear and concise commit message. 
5. Push your branch to your forked repository. 
6. Open a Pull Request from your branch to the main branch of the original PS Lab repository. 
7. In your PR description, please fill out the Pull Request Template and reference the issue it resolves (e.g., "Fixes #123").
8. The project maintainers will review your PR, provide feedback, and merge it once it's ready.

## Coding Conventions

Please refer to this [document](/STYLE_GUIDE.md)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](/CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

Looking forward to your contributions!