// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#region Using directives

using System;
using System.Globalization;
using System.Management.Automation;
using System.Threading;

#endregion

namespace Microsoft.Management.Infrastructure.CimCmdlets
{

    /// <summary>
    /// <param>
    /// Subscription result event args
    /// </param>
    /// </summary>
    internal abstract class CimSubscriptionEventArgs : EventArgs
    {
        /// <summary>
        /// <param>
        /// Returns an Object value for an operation context
        /// </param>
        /// </summary>
        public object Context
        {
            get
            {
                return context;
            }
        }

        protected object context;
    }

    /// <summary>
    /// <param>
    /// Subscription result event args
    /// </param>
    /// </summary>
    internal class CimSubscriptionResultEventArgs : CimSubscriptionEventArgs
    {
        /// <summary>
        /// <param>
        /// subscription result
        /// </param>
        /// </summary>
        public CimSubscriptionResult Result
        {
            get
            {
                return result;
            }
        }

        private CimSubscriptionResult result;

        /// <summary>
        /// <param>Constructor.</param>
        /// </summary>
        /// <param name="theResult"></param>
        public CimSubscriptionResultEventArgs(
            CimSubscriptionResult theResult)
        {
            this.context = null;
            this.result = theResult;
        }
    }

    /// <summary>
    /// <param>
    /// Subscription result event args
    /// </param>
    /// </summary>
    internal class CimSubscriptionExceptionEventArgs : CimSubscriptionEventArgs
    {
        /// <summary>
        /// <param>
        /// subscription result
        /// </param>
        /// </summary>
        public Exception Exception
        {
            get
            {
                return exception;
            }
        }

        private Exception exception;

        /// <summary>
        /// <param>Constructor.</param>
        /// </summary>
        /// <param name="theResult"></param>
        public CimSubscriptionExceptionEventArgs(
            Exception theException)
        {
            this.context = null;
            this.exception = theException;
        }
    }

    /// <summary>
    /// <param>
    /// Implements operations of register-cimindication cmdlet.
    /// </param>
    /// </summary>
    internal sealed class CimRegisterCimIndication : CimAsyncOperation
    {
        /// <summary>
        /// <param>
        /// New subscription result event
        /// </param>
        /// </summary>
        public event EventHandler<CimSubscriptionEventArgs> OnNewSubscriptionResult;

        /// <summary>
        /// <param>
        /// Constructor
        /// </param>
        /// </summary>
        public CimRegisterCimIndication()
            : base()
        {
            this.ackedEvent = new ManualResetEventSlim(false);
        }

        /// <summary>
        /// Start an indication subscription target to the given computer.
        /// </summary>
        /// <param name="computerName">Null stands for localhost.</param>
        /// <param name="nameSpace"></param>
        /// <param name="queryDialect"></param>
        /// <param name="queryExpression"></param>
        /// <param name="operationTimeout"></param>
        public void RegisterCimIndication(
            string computerName,
            string nameSpace,
            string queryDialect,
            string queryExpression,
            UInt32 operationTimeout)
        {
            DebugHelper.WriteLogEx("queryDialect = '{0}'; queryExpression = '{1}'", 0, queryDialect, queryExpression);
            this.TargetComputerName = computerName;
            CimSessionProxy proxy = CreateSessionProxy(computerName, operationTimeout);
            proxy.SubscribeAsync(nameSpace, queryDialect, queryExpression);
            WaitForAckMessage();
        }

        /// <summary>
        /// Start an indication subscription through a given <see cref="CimSession"/>.
        /// </summary>
        /// <param name="cimSession">Cannot be null.</param>
        /// <param name="nameSpace"></param>
        /// <param name="queryDialect"></param>
        /// <param name="queryExpression"></param>
        /// <param name="operationTimeout"></param>
        /// <exception cref="ArgumentNullException">throw if cimSession is null</exception>
        public void RegisterCimIndication(
            CimSession cimSession,
            string nameSpace,
            string queryDialect,
            string queryExpression,
            UInt32 operationTimeout)
        {
            DebugHelper.WriteLogEx("queryDialect = '{0}'; queryExpression = '{1}'", 0, queryDialect, queryExpression);
            if (cimSession == null)
            {
                throw new ArgumentNullException(String.Format(CultureInfo.CurrentUICulture, Strings.NullArgument, @"cimSession"));
            }

            this.TargetComputerName = cimSession.ComputerName;
            CimSessionProxy proxy = CreateSessionProxy(cimSession, operationTimeout);
            proxy.SubscribeAsync(nameSpace, queryDialect, queryExpression);
            WaitForAckMessage();
        }

        #region override methods

        /// <summary>
        /// <param>
        /// Subscribe to the events issued by <see cref="CimSessionProxy"/>.
        /// </param>
        /// </summary>
        /// <param name="proxy"></param>
        protected override void SubscribeToCimSessionProxyEvent(CimSessionProxy proxy)
        {
            DebugHelper.WriteLog("SubscribeToCimSessionProxyEvent", 4);
            // Raise event instead of write object to ps
            proxy.OnNewCmdletAction += this.CimIndicationHandler;
            proxy.OnOperationCreated += this.OperationCreatedHandler;
            proxy.OnOperationDeleted += this.OperationDeletedHandler;
            proxy.EnableMethodResultStreaming = false;
        }

        /// <summary>
        /// <param>
        /// Handler used to handle new action event from
        /// <seealso cref="CimSessionProxy"/> object.
        /// </param>
        /// </summary>
        /// <param name="cimSession">
        /// <seealso cref="CimSession"/> object raised the event
        /// </param>
        /// <param name="actionArgs">Event argument.</param>
        private void CimIndicationHandler(object cimSession, CmdletActionEventArgs actionArgs)
        {
            DebugHelper.WriteLogEx("action is {0}. Disposed {1}", 0, actionArgs.Action, this.Disposed);

            if (this.Disposed)
            {
                return;
            }

            // NOTES: should move after this.Disposed, but need to log the exception
            CimWriteError cimWriteError = actionArgs.Action as CimWriteError;
            if (cimWriteError != null)
            {
                this.exception = cimWriteError.Exception;
                if (!this.ackedEvent.IsSet)
                {
                    // an exception happened
                    DebugHelper.WriteLogEx("an exception happened", 0);
                    this.ackedEvent.Set();
                    return;
                }

                EventHandler<CimSubscriptionEventArgs> temp = this.OnNewSubscriptionResult;
                if (temp != null)
                {
                    DebugHelper.WriteLog("Raise an exception event", 2);

                    temp(this, new CimSubscriptionExceptionEventArgs(this.exception));
                }

                DebugHelper.WriteLog("Got an exception: {0}", 2, exception);
            }

            CimWriteResultObject cimWriteResultObject = actionArgs.Action as CimWriteResultObject;
            if (cimWriteResultObject != null)
            {
                CimSubscriptionResult result = cimWriteResultObject.Result as CimSubscriptionResult;
                if (result != null)
                {
                    EventHandler<CimSubscriptionEventArgs> temp = this.OnNewSubscriptionResult;
                    if (temp != null)
                    {
                        DebugHelper.WriteLog("Raise an result event", 2);
                        temp(this, new CimSubscriptionResultEventArgs(result));
                    }
                }
                else
                {
                    if (!this.ackedEvent.IsSet)
                    {
                        // an ACK message returned
                        DebugHelper.WriteLogEx("an ack message happened", 0);
                        this.ackedEvent.Set();
                        return;
                    }
                    else
                    {
                        DebugHelper.WriteLogEx("an ack message should not happen here", 0);
                    }
                }
            }
        }

        /// <summary>
        /// block the ps thread until ACK message or Error happened.
        /// </summary>
        private void WaitForAckMessage()
        {
            DebugHelper.WriteLogEx();
            this.ackedEvent.Wait();
            if (this.exception != null)
            {
                DebugHelper.WriteLogEx("error happened", 0);
                if (this.Cmdlet != null)
                {
                    DebugHelper.WriteLogEx("Throw Terminating error", 1);

                    // throw terminating error
                    ErrorRecord errorRecord = ErrorToErrorRecord.ErrorRecordFromAnyException(
                        new InvocationContext(this.TargetComputerName, null), this.exception, null);
                    this.Cmdlet.ThrowTerminatingError(errorRecord);
                }
                else
                {
                    DebugHelper.WriteLogEx("Throw exception", 1);
                    // throw exception out
                    throw this.exception;
                }
            }

            DebugHelper.WriteLogEx("ACK happened", 0);
        }
        #endregion

        #region internal property
        /// <summary>
        /// The cmdlet object who issue this subscription,
        /// to throw ThrowTerminatingError
        /// in case there is a subscription failure
        /// </summary>
        /// <param name="cmdlet"></param>
        internal Cmdlet Cmdlet
        {
            set;
            get;
        }

        /// <summary>
        /// target computername
        /// </summary>
        internal String TargetComputerName
        {
            set;
            get;
        }

        #endregion

        #region private methods
        /// <summary>
        /// <param>
        /// Create <see cref="CimSessionProxy"/> and set properties
        /// </param>
        /// </summary>
        /// <param name="computerName"></param>
        /// <param name="timeout"></param>
        /// <returns></returns>
        private CimSessionProxy CreateSessionProxy(
            string computerName,
            UInt32 timeout)
        {
            CimSessionProxy proxy = CreateCimSessionProxy(computerName);
            proxy.OperationTimeout = timeout;
            return proxy;
        }

        /// <summary>
        /// Create <see cref="CimSessionProxy"/> and set properties
        /// </summary>
        /// <param name="session"></param>
        /// <param name="timeout"></param>
        /// <returns></returns>
        private CimSessionProxy CreateSessionProxy(
            CimSession session,
            UInt32 timeout)
        {
            CimSessionProxy proxy = CreateCimSessionProxy(session);
            proxy.OperationTimeout = timeout;
            return proxy;
        }
        #endregion

        #region private members

        /// <summary>
        /// Exception occurred while start the subscription
        /// </summary>
        internal Exception Exception
        {
            get
            {
                return exception;
            }
        }

        private Exception exception;

        #endregion

    }//End Class
}//End namespace
