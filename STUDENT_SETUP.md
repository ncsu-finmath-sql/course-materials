# Student Setup Guide

Do this once, before the first class. Budget about 30 minutes. If anything goes wrong, jump to
[If something goes wrong](#if-something-goes-wrong) - nobody is expected to know this already.

You need: a computer (Mac or Windows), an internet connection, and a GitHub account.

## Step 1 - Create a GitHub account

1. Go to <https://github.com> and click **Sign up**. Use any email; your NC State address is fine.
2. Tell your instructor your **GitHub username** (not your email) when asked.
3. *(Recommended)* Apply for free student benefits at <https://education.github.com/students>. Approval can
   take days, so apply now. You will not need it until Copilot is introduced, and **no grade depends on it**.

> 📸 *[Screenshot: GitHub sign-up page]*

## Step 2 - Install Visual Studio Code ("VS Code")

Download from <https://code.visualstudio.com> and install with the default options.

## Step 3 - Install Python

The practice checker uses Python behind the scenes. You never write Python.

- **Windows:** download Python 3.12 or newer from <https://www.python.org/downloads/>. On the first
  installer screen, **tick "Add python.exe to PATH"**, then click Install.
- **Mac:** download the installer from the same page and run it. (If you already have Python 3, skip this.)

## Step 4 - Install Git

- **Windows:** <https://git-scm.com/download/win> (default options are fine).
- **Mac:** open the **Terminal** app, type `git --version`, press Enter. If a window offers to install
  developer tools, click Install.

## Step 5 - Accept your repository invitation

Your instructor will invite you to a private repository named like `sql-yourgithubusername`.

1. Check the email for your GitHub account (also check Spam), or go to <https://github.com/notifications>.
2. Click **View invitation**, then **Accept invitation**.

> 📸 *[Screenshot: the invitation page with the green Accept button]*

## Step 6 - Open your repository in VS Code

1. Open VS Code. Press **Cmd+Shift+P** (Mac) / **Ctrl+Shift+P** (Windows) to open the command palette.
2. Type **Git: Clone** and press Enter. Choose **Clone from GitHub**.
3. VS Code asks you to sign in to GitHub. Click **Allow** and complete the sign-in in your browser.
4. Pick your repository (`ncsu-finmath-sql/sql-...`), choose a folder to keep it in (e.g. Documents), and click
   **Select as Repository Destination**.
5. When asked **Would you like to open the cloned repository?**, click **Open**. Click **Yes, I trust the
   authors**.
6. In the bottom-right a pop-up says *This workspace has extension recommendations*. Click **Install**.

> 📸 *[Screenshot: the Git: Clone prompt and the repository list]*

## Step 7 - Try it

1. In the left sidebar (the **Explorer**), open `assignment-01` and click `q1.sql`.
2. Press **Cmd+Shift+B** (Mac) / **Ctrl+Shift+B** (Windows). The first run takes about a minute
   because it prepares itself; it needs internet. Later runs are instant.
3. A panel opens at the bottom. Since `q1.sql` has no query yet it says so. That is the expected result.

To make sure everything works, add this line under the comments in `q1.sql` and press Ctrl/Cmd+Shift+B again:

```sql
SELECT * FROM prices LIMIT 5;
```

You should see a table of 5 rows. Then **delete that line or replace it with your real answer**.

> 📸 *[Screenshot: result table in the bottom panel]*

## Doing an assignment

1. Open `assignment-NN/README.md` and click the **Open Preview** button (top right) to read it nicely.
2. Write your answers in the `.sql` files.
3. Test each query: open the file, press Cmd/Ctrl+Shift+B.
4. **Check your score:** press Cmd/Ctrl+Shift+P, type **Tasks: Run Task**, choose **Check Assignment 1**
   (or the number you're working on).

## Saving your work to GitHub ("commit and push")

Do this every time you want your work graded or backed up.

1. Click the **Source Control** icon in the left bar (it looks like a branching line; it shows a number badge).
2. Type a short message in the box, e.g. `Finish question 3`.
3. Click **Commit**. If it asks *Would you like to stage all changes*, click **Yes**.
4. Click **Sync Changes** (or **Push**). If it asks whether to pull first, click **OK**.

> 📸 *[Screenshot: Source Control panel with the message box and Commit button]*

## Seeing the online practice check

1. Go to your repository page on <https://github.com> (signed in).
2. Click the **Actions** tab. Click the newest run (a green ✓ or red ✗ next to your commit message).
3. Click **check**, then scroll to the step **Check my SQL**. Or click **Summary** at the top-left for a score table.

A red ✗ does **not** mean you did something wrong with Git - read the score and hints.
The check is practice feedback; your official grade is recorded separately by your instructor.

## Getting new assignments

When your instructor releases a new assignment, a new folder appears after you click **Sync Changes** in the
Source Control panel.

## If something goes wrong

| Problem | Try this |
|---|---|
| Ctrl/Cmd+Shift+B does nothing | Make sure a `.sql` file is open and selected in the editor. |
| "python not found" / "python3 not found" | Re-install Python (Step 3). On Windows tick **Add to PATH**, then close and re-open VS Code. |
| "Setup failed while installing DuckDB" | Check your internet and try again. Campus Wi-Fi blocking? Try a hotspot or ask for help. |
| Clone asks for a password | Use **Clone from GitHub** and sign in through the browser. |
| Can't see the repository to clone | You haven't accepted the invitation yet (Step 5). |
| Sync/Push says "rejected" | Click **Sync Changes** again (it pulls first), then push. Never force-push. |
| Everything is broken | Use **GitHub Codespaces** (below) and email your instructor. |

### Optional fallback: GitHub Codespaces

On your repository page click the green **Code** button > **Codespaces** > **Create codespace on main**. You get
VS Code in the browser with everything pre-installed. Codespaces has a monthly free allowance, so use it only if local
setup fails, and stop it when done (bottom-left menu > **Stop Current Codespace**).

## Rules that protect you

- Don't edit files in `tools/`, `data/`, or `.github/`. Official grading ignores them anyway, and changing them to
  influence a score is an academic integrity violation.
- Keep each answer in its own `qN.sql` file, with the original file name.
