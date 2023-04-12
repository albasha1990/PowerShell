// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

#nullable enable

using System.Collections.Generic;
using System.IO;
using System.Management.Automation.Internal;
using System.Management.Automation.Language;
using System.Management.Automation.Runspaces;
using System.Threading;

namespace System.Management.Automation.Subsystem.Feedback
{
    /// <summary>
    /// Types of trigger for the feedback provider.
    /// </summary>
    [Flags]
    public enum FeedbackTrigger
    {
        /// <summary>
        /// The last command line is comment only.
        /// </summary>
        Comment = 0x0001,

        /// <summary>
        /// The last command line executed successfully.
        /// </summary>
        Success = 0x0002,

        /// <summary>
        /// The last command line failed due to a command-not-found error.
        /// This is a special case of <see cref="Error"/>.
        /// </summary>
        CommandNotFound = 0x0004,

        /// <summary>
        /// The last command line failed with an error record.
        /// This includes the case of command-not-found error.
        /// </summary>
        Error = CommandNotFound | 0x0008,

        /// <summary>
        /// All possible triggers.
        /// </summary>
        All = Comment | Success | Error
    }

    /// <summary>
    /// Layout for displaying the recommended actions.
    /// </summary>
    public enum FeedbackDisplayLayout
    {
        /// <summary>
        /// Display one recommended action per row.
        /// </summary>
        Portrait,

        /// <summary>
        /// Display all recommended actions in the same row.
        /// </summary>
        Landscape,
    }

    /// <summary>
    /// 
    /// </summary>
    public sealed class FeedbackContext
    {
        /// <summary>
        /// Gets the feedback trigger.
        /// </summary>
        public FeedbackTrigger Trigger { get; }

        /// <summary>
        /// Gets the last command line that was just executed.
        /// </summary>
        public string CommandLine { get; }

        /// <summary>
        /// Gets the abstract syntax tree (AST) generated from parsing the last command line.
        /// </summary>
        public Ast CommandLineAst { get; }

        /// <summary>
        /// Gets the tokens generated from parsing the last command line.
        /// </summary>
        public IReadOnlyList<Token> CommandLineTokens { get; }

        /// <summary>
        /// Gets the current location of the default session.
        /// </summary>
        public PathInfo CurrentLocation { get; }

        /// <summary>
        /// Gets the last error record generated from executing the last command line.
        /// </summary>
        public ErrorRecord? LastError { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="FeedbackContext"/> class.
        /// </summary>
        /// <param name="trigger">The trigger of this feedback call.</param>
        /// <param name="commandLine">The command line that was just executed.</param>
        /// <param name="cwd">The current location of the default session.</param>
        /// <param name="lastError">The error that was triggerd by the last command line.</param>
        public FeedbackContext(FeedbackTrigger trigger, string commandLine, PathInfo cwd, ErrorRecord? lastError)
        {
            ArgumentException.ThrowIfNullOrEmpty(commandLine);
            ArgumentNullException.ThrowIfNull(cwd);

            Trigger = trigger;
            CommandLine = commandLine;
            CommandLineAst = Parser.ParseInput(commandLine, out Token[] tokens, out _);
            CommandLineTokens = tokens;
            LastError = lastError;
            CurrentLocation = cwd;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="FeedbackContext"/> class.
        /// </summary>
        /// <param name="trigger">The trigger of this feedback call.</param>
        /// <param name="commandLineAst">The abstract syntax tree (AST) from parsing the last command line.</param>
        /// <param name="commandLineTokens">The tokens from parsing the last command line.</param>
        /// <param name="cwd">The current location of the default session.</param>
        /// <param name="lastError">The error that was triggerd by the last command line.</param>
        public FeedbackContext(FeedbackTrigger trigger, Ast commandLineAst, Token[] commandLineTokens, PathInfo cwd, ErrorRecord? lastError)
        {
            ArgumentNullException.ThrowIfNull(commandLineAst);
            ArgumentNullException.ThrowIfNull(commandLineTokens);
            ArgumentNullException.ThrowIfNull(cwd);

            Trigger = trigger;
            CommandLine = commandLineAst.Extent.Text;
            CommandLineAst = commandLineAst;
            CommandLineTokens = commandLineTokens;
            LastError = lastError;
            CurrentLocation = cwd;
        }
    }

    /// <summary>
    /// The class represents a feedback item generated by the feedback provider.
    /// </summary>
    public sealed class FeedbackItem
    {
        /// <summary>
        /// Gets the description message about this feedback.
        /// </summary>
        public string Header { get; }

        /// <summary>
        /// Gets the footer message about this feedback.
        /// </summary>
        public string? Footer { get; }

        /// <summary>
        /// Gets the recommended actions -- command lines or even code snippets to run.
        /// </summary>
        public List<string>? RecommendedActions { get; }

        /// <summary>
        /// Gets the layout to use for displaying the recommended actions.
        /// </summary>
        public FeedbackDisplayLayout Layout { get; }

        /// <summary>
        /// Gets or sets the next feedback item, if there is one.
        /// </summary>
        public FeedbackItem? Next { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="FeedbackItem"/> class.
        /// </summary>
        /// <param name="header">The description message (must be not null or empty).</param>
        /// <param name="actions">The recommended actions to take (optional).</param>
        public FeedbackItem(string header, List<string>? actions)
            : this(header, actions, footer: null, FeedbackDisplayLayout.Portrait)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="FeedbackItem"/> class.
        /// </summary>
        /// <param name="header">The description message (must be not null or empty).</param>
        /// <param name="actions">The recommended actions to take (optional).</param>
        /// <param name="layout">The layout for displaying the actions.</param>
        public FeedbackItem(string header, List<string>? actions, FeedbackDisplayLayout layout)
            : this(header, actions, footer: null, layout)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="FeedbackItem"/> class.
        /// </summary>
        /// <param name="header">The description message (must be not null or empty).</param>
        /// <param name="actions">The recommended actions to take (optional).</param>
        /// <param name="footer">The footer message (optional).</param>
        /// <param name="layout">The layout for displaying the actions.</param>
        public FeedbackItem(string header, List<string>? actions, string? footer, FeedbackDisplayLayout layout)
        {
            ArgumentException.ThrowIfNullOrEmpty(header);

            Header = header;
            RecommendedActions = actions;
            Footer = footer;
            Layout = layout;
        }
    }

    /// <summary>
    /// Interface for implementing a feedback provider on command failures.
    /// </summary>
    public interface IFeedbackProvider : ISubsystem
    {
        /// <summary>
        /// Default implementation. No function is required for a feedback provider.
        /// </summary>
        Dictionary<string, string>? ISubsystem.FunctionsToDefine => null;

        /// <summary>
        /// Gets the types of trigger for this feedback provider.
        /// </summary>
        /// <remarks>
        /// The default implementation triggers a feedback provider by <see cref="FeedbackTrigger.CommandNotFound"/> only.
        /// </remarks>
        FeedbackTrigger Trigger => FeedbackTrigger.CommandNotFound;

        /// <summary>
        /// Gets feedback based on the given commandline and error record.
        /// </summary>
        /// <param name="context">The context for the feedback call.</param>
        /// <param name="token">The cancellation token to cancel the operation.</param>
        /// <returns>The feedback item.</returns>
        FeedbackItem? GetFeedback(FeedbackContext context, CancellationToken token);
    }

    internal sealed class GeneralCommandErrorFeedback : IFeedbackProvider
    {
        private readonly Guid _guid;

        internal GeneralCommandErrorFeedback()
        {
            _guid = new Guid("A3C6B07E-4A89-40C9-8BE6-2A9AAD2786A4");
        }

        public Guid Id => _guid;

        public string Name => "general";

        public string Description => "The built-in general feedback source for command errors.";

        public FeedbackItem? GetFeedback(FeedbackContext context, CancellationToken token)
        {
            var rsToUse = Runspace.DefaultRunspace;
            if (rsToUse is null)
            {
                return null;
            }

            // This feedback provider is only triggered by 'CommandNotFound' error, so the
            // 'LastError' property is guaranteed to be not null.
            ErrorRecord lastError = context.LastError!;
            SessionState sessionState = rsToUse.ExecutionContext.SessionState;

            var target = (string)lastError.TargetObject;
            CommandInvocationIntrinsics invocation = sessionState.InvokeCommand;

            // See if target is actually an executable file in current directory.
            var localTarget = Path.Combine(".", target);
            var command = invocation.GetCommand(
                localTarget,
                CommandTypes.Application | CommandTypes.ExternalScript);

            if (command is not null)
            {
                return new FeedbackItem(
                    StringUtil.Format(SuggestionStrings.Suggestion_CommandExistsInCurrentDirectory, target),
                    new List<string> { localTarget });
            }

            // Check fuzzy matching command names.
            if (ExperimentalFeature.IsEnabled("PSCommandNotFoundSuggestion"))
            {
                var pwsh = PowerShell.Create(RunspaceMode.CurrentRunspace);
                var results = pwsh.AddCommand("Get-Command")
                        .AddParameter("UseFuzzyMatching")
                        .AddParameter("FuzzyMinimumDistance", 1)
                        .AddParameter("Name", target)
                    .AddCommand("Select-Object")
                        .AddParameter("First", 5)
                        .AddParameter("Unique")
                        .AddParameter("ExpandProperty", "Name")
                    .Invoke<string>();

                if (results.Count > 0)
                {
                    return new FeedbackItem(
                        SuggestionStrings.Suggestion_CommandNotFound,
                        new List<string>(results),
                        FeedbackDisplayLayout.Landscape);
                }
            }

            return null;
        }
    }
}
