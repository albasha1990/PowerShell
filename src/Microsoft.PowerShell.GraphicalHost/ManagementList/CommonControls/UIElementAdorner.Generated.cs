// -----------------------------------------------------------------------
//  <copyright file="UIElementAdorner.Generated.cs" company="Microsoft">
//      Copyright (c) Microsoft Corporation.  All rights reserved.
//  </copyright>
//
//  <auto-generated>
//      This code was generated by a tool. DO NOT EDIT
//
//      Changes to this file may cause incorrect behavior and will be lost if
//      the code is regenerated.
//  </auto-generated>
// -----------------------------------------------------------------------

#region StyleCop Suppression - generated code
using System;
using System.ComponentModel;
using System.Windows;

namespace Microsoft.Management.UI.Internal
{

    /// <summary>
    /// An Adorner which displays a given UIElement.
    /// </summary>
    [Localizability(LocalizationCategory.None)]
    partial class UIElementAdorner
    {
        //
        // Child dependency property
        //
        /// <summary>
        /// Identifies the Child dependency property.
        /// </summary>
        public static readonly DependencyProperty ChildProperty = DependencyProperty.Register( "Child", typeof(UIElement), typeof(UIElementAdorner), new FrameworkPropertyMetadata( null, FrameworkPropertyMetadataOptions. AffectsArrange | FrameworkPropertyMetadataOptions.AffectsMeasure , ChildProperty_PropertyChanged) );

        /// <summary>
        /// Gets or sets the child element.
        /// </summary>
        [Bindable(true)]
        [Category("Common Properties")]
        [Description("Gets or sets the child element.")]
        [Localizability(LocalizationCategory.None)]
        public UIElement Child
        {
            get
            {
                return (UIElement) GetValue(ChildProperty);
            }
            set
            {
                SetValue(ChildProperty,value);
            }
        }

        static private void ChildProperty_PropertyChanged(DependencyObject o, DependencyPropertyChangedEventArgs e)
        {
            UIElementAdorner obj = (UIElementAdorner) o;
            obj.OnChildChanged( new PropertyChangedEventArgs<UIElement>((UIElement)e.OldValue, (UIElement)e.NewValue) );
        }

        /// <summary>
        /// Occurs when Child property changes.
        /// </summary>
        public event EventHandler<PropertyChangedEventArgs<UIElement>> ChildChanged;

        /// <summary>
        /// Called when Child property changes.
        /// </summary>
        private void RaiseChildChanged(PropertyChangedEventArgs<UIElement> e)
        {
            var eh = this.ChildChanged;
            if(eh != null)
            {
                eh(this,e);
            }
        }

        /// <summary>
        /// Called when Child property changes.
        /// </summary>
        protected virtual void OnChildChanged(PropertyChangedEventArgs<UIElement> e)
        {
            OnChildChangedImplementation(e);
            RaiseChildChanged(e);
        }

        partial void OnChildChangedImplementation(PropertyChangedEventArgs<UIElement> e);

    }
}
#endregion
