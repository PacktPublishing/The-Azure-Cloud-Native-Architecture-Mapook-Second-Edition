string blobName = Environment.GetEnvironmentVariable("BlobName");
if (string.IsNullOrEmpty(blobName))
    throw new ApplicationException("No blob transmitted");    
    
//pretend to handle the blob
Thread.Sleep(new Random().Next(2000,15000));
Console.WriteLine("job done");