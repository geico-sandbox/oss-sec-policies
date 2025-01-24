import * as core from '@actions/core';
import * as github from '@actions/github';
import * as glob from 'glob';
import * as fs from 'fs';
import * as path from 'path';



async function run() {
    try {
        const token = process.env.GITHUB_TOKEN;
        if (!token) {
            core.setFailed('GITHUB_TOKEN is not set');
            return;
        }
        const octokit = github.getOctokit(token);
        const { context } = github;
        const prNumber = context.payload.pull_request?.number;

        const configPath = path.resolve(__dirname, '../config/config.json');
        const configFile = fs.readFileSync(configPath, 'utf-8');
        const config = JSON.parse(configFile);


        if (!prNumber) {
            core.setFailed('No pull request number found.');
            return;
        }

        const adoPatterns = config.adoPatterns;
        const internalPatterns = config.internalPatterns;
        let found = false;

        // Function to check ADO references
        const checkAdoReferences = async () => {
            // Fetch the PR details
            const { data: prDetails } = await octokit.rest.pulls.get({
                ...context.repo,
                pull_number: prNumber,
            });

            // Check the PR title
            for (const pattern of adoPatterns) {
                if (new RegExp(pattern).test(prDetails.title)) {
                    core.error(`Error: ADO work item references found in PR title: ${pattern}`);
                    found = true;
                }
            }

            // Check the PR description
            for (const pattern of adoPatterns) {
                if (new RegExp(pattern).test(prDetails.body || '')) {
                    core.error(`Error: ADO work item references found in PR description: ${pattern}`);
                    found = true;
                }
            }

            // Fetch the PR comments
            const { data: prComments } = await octokit.rest.issues.listComments({
                ...context.repo,
                issue_number: prNumber,
            });

            // Check the PR comments
            for (const comment of prComments) {
                for (const pattern of adoPatterns) {
                    if (new RegExp(pattern).test(comment.body || '')) {
                        core.error(`Error: ADO work item references found in PR comments: ${pattern}`);
                        found = true;
                    }
                }
            }
        };

        // Function to check internal package management system references
        const checkInternalReferences = async () => {
            const files = glob.sync('**/*', { nodir: true, ignore: ['node_modules/**', '.git/**'] });
            for (const file of files) {
                if (path.resolve(file) === configPath) {
                    continue;
                }
                const content = fs.readFileSync(file, 'utf8');
                for (const pattern of internalPatterns) {
                    if (new RegExp(pattern).test(content)) {
                        core.error(`Error: Found reference to internal package management system in file ${file}: ${pattern}`);
                        found = true;
                    }
                }
            }
        };

        // Run both checks in parallel
        await Promise.all([checkAdoReferences(), checkInternalReferences()]);

        if (found) {
            core.setFailed('Error: References to ADO work items or internal package management systems found.');
        } else {
            core.info('No references to ADO work items or internal package management systems found.');
        }
    } catch (error) {
        if (error instanceof Error) {
            core.setFailed(error.message);
        } else {
            core.setFailed(String(error));
        }
    }
}

run();