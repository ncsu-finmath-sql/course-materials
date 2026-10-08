# Using GitHub Copilot and other AI tools

> **Artificial Intelligence and Coding Assistants**
> Students will initially complete SQL exercises without AI coding assistance so that they develop foundational SQL and
> data-analysis skills. Later in the course, tools such as GitHub Copilot may be used to assist with debugging,
> exploration, and code generation. Students remain responsible for understanding, validating, and explaining all
> submitted code and analytical results. AI-generated output should be treated as a draft to evaluate, not as an
> authoritative answer.

## Before Assignment 4: AI off

Your repository's recommended extensions deliberately **do not include Copilot**. If you have it installed, disable it
for this repository: click the Copilot icon at the bottom of VS Code and choose **Disable Completions**, or use the
Extensions panel > Copilot > **Disable (Workspace)**. Don't paste assignment questions into ChatGPT or any other chatbot.

## From Assignment 4

You may use Copilot as described in each assignment README. Good habits, whatever the tool says:

- Does the query use only columns that really exist in the table? (AI often invents columns.)
- Could a join duplicate rows? Did you check `COUNT(*)` before and after?
- Are `NULL`s, dates, and the time period handled correctly?
- Is the number financially meaningful? Run a small test query that confirms it.

Free Copilot access for students: <https://education.github.com/students>. Apply early, but no assignment requires it.
