#region Namespaces
using System;
using System.IO;
using System.Net.Http;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.Dts.Runtime;
#endregion

[Microsoft.SqlServer.Dts.Tasks.ScriptTask.SSISScriptTaskEntryPointAttribute]
public partial class ScriptMain : Microsoft.SqlServer.Dts.Tasks.ScriptTask.VSTARTScriptObjectModelBase
{
    public void Main()
    {
        string outputFile = @"C:\Users\user\Desktop\Projet_DW_F1\api_standings.csv";
        string apiUrl = "https://api.jolpi.ca/ergast/f1/2023/driverStandings.json";

        try
        {
            using (var client = new System.Net.Http.HttpClient())
            {
                client.DefaultRequestHeaders.Add("User-Agent", "SSIS-ETL-F1");
                string json = client.GetStringAsync(apiUrl).Result;

                var lines = new System.Text.StringBuilder();
                lines.AppendLine("season,round,driverCode,driverId,points,wins,position");

                var standingBlocks = Regex.Matches(json,
                    "\"position\":\"(\\d+)\".*?\"points\":\"([^\"]+)\".*?\"wins\":\"([^\"]+)\"" +
                    ".*?\"driverId\":\"([^\"]+)\".*?\"code\":\"([^\"]+)\"",
                    RegexOptions.Singleline);

                foreach (Match m in standingBlocks)
                {
                    lines.AppendLine($"2023,22,{m.Groups[5].Value},{m.Groups[4].Value},{m.Groups[2].Value},{m.Groups[3].Value},{m.Groups[1].Value}");
                }

                File.WriteAllText(outputFile, lines.ToString());
            }
            Dts.TaskResult = (int)DTSExecResult.Success;
        }
        catch (Exception ex)
        {
            Dts.Events.FireError(0, "API Load", ex.Message, "", 0);
            Dts.TaskResult = (int)DTSExecResult.Failure;
        }
    }
}