// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System.Runtime.Serialization;
using System.Security.Permissions;

namespace System.Management.Automation
{
    /// <summary>
    /// This is a wrapper for exception class
    /// <see cref="System.ArgumentException"/>
    /// which provides additional information via
    /// <see cref="System.Management.Automation.IContainsErrorRecord"/>.
    /// </summary>
    /// <remarks>
    /// Instances of this exception class are usually generated by the
    /// Monad Engine.  It is unusual for code outside the Monad Engine
    /// to create an instance of this class.
    /// </remarks>
    [Serializable]
    public class PSArgumentException
            : ArgumentException, IContainsErrorRecord
    {
        #region ctor
        /// <summary>
        /// Initializes a new instance of the PSArgumentException class.
        /// </summary>
        /// <returns>Constructed object.</returns>
        public PSArgumentException()
            : base()
        {
        }

        /// <summary>
        /// Initializes a new instance of the PSArgumentException class.
        /// </summary>
        /// <param name="message"></param>
        /// <returns>Constructed object.</returns>
        /// <remarks>
        /// Per MSDN, the parameter is message.
        /// I confirm this experimentally as well.
        /// </remarks>
        public PSArgumentException(string message)
            : base(message)
        {
        }

        /// <summary>
        /// Initializes a new instance of the PSArgumentException class.
        /// </summary>
        /// <param name="paramName"></param>
        /// <param name="message"></param>
        /// <returns>Constructed object.</returns>
        /// <remarks>
        /// Note the unusual order of the construction parameters.
        /// ArgumentException has this ctor form and we imitate it here.
        /// </remarks>
        public PSArgumentException(string message, string paramName)
                : base(message, paramName)
        {
            _message = message;
        }

        #region Serialization
        /// <summary>
        /// Initializes a new instance of the PSArgumentException class
        /// using data serialized via
        /// <see cref="System.Runtime.Serialization.ISerializable"/>
        /// </summary>
        /// <param name="info">Serialization information.</param>
        /// <param name="context">Streaming context.</param>
        /// <returns>Constructed object.</returns>
        protected PSArgumentException(SerializationInfo info,
                           StreamingContext context)
                : base(info, context)
        {
            _errorId = info.GetString("ErrorId");
            _message = info.GetString("PSArgumentException_MessageOverride");
        }

        /// <summary>
        /// Serializer for <see cref="System.Runtime.Serialization.ISerializable"/>
        /// </summary>
        /// <param name="info">Serialization information.</param>
        /// <param name="context">Streaming context.</param>
        [SecurityPermissionAttribute(SecurityAction.Demand, SerializationFormatter = true)]
        public override void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            if (info == null)
            {
                throw new PSArgumentNullException("info");
            }

            base.GetObjectData(info, context);
            info.AddValue("ErrorId", _errorId);
            info.AddValue("PSArgumentException_MessageOverride", _message);
        }
        #endregion Serialization

        /// <summary>
        /// Initializes a new instance of the PSArgumentException class.
        /// </summary>
        /// <param name="message"></param>
        /// <param name="innerException"></param>
        /// <returns>Constructed object.</returns>
        public PSArgumentException(string message,
                                    Exception innerException)
                : base(message, innerException)
        {
            _message = message;
        }
        #endregion ctor

        /// <summary>
        /// Additional information about the error.
        /// </summary>
        /// <value></value>
        /// <remarks>
        /// Note that ErrorRecord.Exception is
        /// <see cref="System.Management.Automation.ParentContainsErrorRecordException"/>.
        /// </remarks>
        public ErrorRecord ErrorRecord
        {
            get
            {
                if (_errorRecord == null)
                {
                    _errorRecord = new ErrorRecord(
                        new ParentContainsErrorRecordException(this),
                        _errorId,
                        ErrorCategory.InvalidArgument,
                        null);
                }

                return _errorRecord;
            }
        }

        private ErrorRecord _errorRecord;
        private string _errorId = "Argument";

        /// <summary>
        /// See <see cref="System.Exception.Message"/>
        /// </summary>
        /// <remarks>
        /// Exception.Message is get-only, but you can effectively
        /// set it in a subclass by overriding this virtual property.
        /// </remarks>
        /// <value></value>
        public override string Message
        {
            get { return string.IsNullOrEmpty(_message) ? base.Message : _message; }
        }

        private string _message;
    }
}

