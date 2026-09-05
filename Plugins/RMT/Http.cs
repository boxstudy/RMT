using System;
using System.IO;
using System.Net.Http;
using System.Net.NetworkInformation;
using System.Threading;
using System.Threading.Tasks;

namespace RMT
{
    public class Http
    {
        private static readonly HttpClient SharedClient;

        private readonly object _statusLock = new object();
        private int _statusState;      // 0=idle 1=running 2=ready
        private string _statusResult = "";
        private int _statusSeq;        // 防止过期回调覆盖新请求

        static Http()
        {
            try
            {
                System.Net.ServicePointManager.SecurityProtocol |=
                    (System.Net.SecurityProtocolType)3072; // Tls12
            }
            catch { }

            SharedClient = new HttpClient();
            SharedClient.Timeout = TimeSpan.FromSeconds(15);
        }

        /// <summary>
        /// 异步拉取服务器状态（不阻塞调用线程）。
        /// AHK：BeginGetStatus → 定时器轮询 GetStatusState，为 2 时 TakeStatusResult。
        /// </summary>
        public void BeginGetStatus(string version = "")
        {
            int seq;
            lock (_statusLock)
            {
                if (_statusState == 1)
                    return;
                _statusState = 1;
                _statusResult = "";
                _statusSeq++;
                seq = _statusSeq;
            }

            string ver = version ?? "";
            Task.Run(async () =>
            {
                string result = "";
                try
                {
                    result = await GetStatusCoreAsync(ver).ConfigureAwait(false);
                }
                catch
                {
                    result = "";
                }

                lock (_statusLock)
                {
                    if (seq != _statusSeq)
                        return;
                    _statusResult = result ?? "";
                    _statusState = 2;
                }
            });
        }

        /// <summary>0=空闲 1=进行中 2=已完成可取结果</summary>
        public int GetStatusState()
        {
            lock (_statusLock)
                return _statusState;
        }

        /// <summary>取走异步结果并回到 idle；未完成时返回空串。</summary>
        public string TakeStatusResult()
        {
            lock (_statusLock)
            {
                if (_statusState != 2)
                    return "";
                string r = _statusResult ?? "";
                _statusResult = "";
                _statusState = 0;
                return r;
            }
        }

        /// <summary>
        /// 同步获取状态（兼容旧调用；会阻塞，优先用 BeginGetStatus）。
        /// </summary>
        public string GetStatus(string version = "")
        {
            try
            {
                return GetStatusCoreAsync(version ?? "").ConfigureAwait(false).GetAwaiter().GetResult() ?? "";
            }
            catch
            {
                return "";
            }
        }

        private static async Task<string> GetStatusCoreAsync(string version)
        {
            string deviceId = Device.GetDeviceId();
            if (deviceId == "")
                return "";

            if (!NetworkInterface.GetIsNetworkAvailable())
                return "";

            string url = "http://39.108.96.160:3000/getstatus?id=" + Uri.EscapeDataString(deviceId)
                + "&version=" + Uri.EscapeDataString(version ?? "");

            HttpResponseMessage response = await SharedClient.GetAsync(url).ConfigureAwait(false);
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadAsStringAsync().ConfigureAwait(false) ?? "";
        }

        /// <summary>
        /// 同步上传文件到服务器
        /// </summary>
        public string UploadFile(string filePath)
        {
            string uploadUrl = "http://39.108.96.160:3000/upload";
            string formDataName = "file";
            string deviceId = Device.GetDeviceId();

            if (string.IsNullOrEmpty(filePath))
                return "文件路径不能为空";

            if (!File.Exists(filePath))
                return "文件不存在: " + filePath;

            if (deviceId == "")
                return "信息不完整，请通过软件交流群共享上传配置";

            try
            {
                using (var formData = new MultipartFormDataContent())
                using (var fileStream = File.OpenRead(filePath))
                {
                    var fileContent = new StreamContent(fileStream);
                    string fileName = Path.GetFileName(filePath);
                    formData.Add(fileContent, formDataName, fileName);
                    formData.Add(new StringContent(deviceId), "deviceId");

                    var response = SharedClient.PostAsync(uploadUrl, formData).ConfigureAwait(false).GetAwaiter().GetResult();
                    response.EnsureSuccessStatusCode();
                    return response.Content.ReadAsStringAsync().ConfigureAwait(false).GetAwaiter().GetResult();
                }
            }
            catch (AggregateException ex)
            {
                throw new Exception("网络请求失败: " + (ex.InnerException != null ? ex.InnerException.Message : ex.Message), ex);
            }
            catch (Exception ex)
            {
                throw new Exception("上传文件时发生错误: " + ex.Message, ex);
            }
        }
    }
}
