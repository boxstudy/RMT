// =============================================================================
// Shared static utilities: LengthPrefix, visual-tree lookups
// =============================================================================
using System;
using System.Text;
using System.Windows;
using System.Windows.Media;

internal static class BridgeUtil
{
    internal static T FindVisualChild<T>(DependencyObject obj) where T : DependencyObject
    {
        if (obj != null)
        {
            for (int i = 0; i < System.Windows.Media.VisualTreeHelper.GetChildrenCount(obj); i++)
            {
                var child = System.Windows.Media.VisualTreeHelper.GetChild(obj, i);
                if (child is T) return (T)child;
                T childItem = FindVisualChild<T>(child);
                if (childItem != null) return childItem;
            }
        }
        return null;
    }

    // Length-prefixed encoding helper: encodes a value as "BYTELEN:rawvalue"
    // This replaces Base64 encoding — zero overhead, binary-safe for any characters
    // including emojis, pipes, newlines, null chars, CJK, etc.
    internal static string LengthPrefix(string val)
    {
        if (val == null) val = "";
        // 转义 \r\n 为 &#x0D;/&#x0A;，避免多行值把按 \n 拆行的载荷截断（AHK DecodeValue 侧对称还原）
        string escaped = val.Replace("\r", "&#x0D;").Replace("\n", "&#x0A;");
        int byteLen = Encoding.UTF8.GetByteCount(escaped);
        return byteLen + ":" + escaped;
    }
    internal static DependencyObject FindVisualChildByName(DependencyObject parent, string name)
    {
        if (parent == null) return null;
        int count = VisualTreeHelper.GetChildrenCount(parent);
        for (int i = 0; i < count; i++)
        {
            var child = VisualTreeHelper.GetChild(parent, i);
            if (child is FrameworkElement)
            {
                var fe = (FrameworkElement)child;
                if (fe.Name == name) return child;
            }
            var found = FindVisualChildByName(child, name);
            if (found != null) return found;
        }
        return null;
    }

}
