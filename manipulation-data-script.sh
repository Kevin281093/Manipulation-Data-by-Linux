#!/bin/bash

# Kiểm tra sự tồn tại của file CSV
if [ ! -f "tmdb-movies.csv" ]; then
    echo "File tmdb-movies.csv không tồn tại!"
    exit 1
fi

# Sắp xếp các bộ phim theo ngày phát hành giảm dần rồi lưu ra một file mới

csvsort -c "release-date" -r tmdb-movies.csv > sorted-tmdb-movies.csv

# Lọc ra các bộ phim có đánh giá trung bình trên 7.5 rồi lưu ra một file mới
csvgrep -c "vote-average" -r "^(7\.5|7\.[6-9]|[8-9]\.\d+|\d{2,})" tmdb-movies.csv > filtered-tmdb-movies.csv

# Tìm ra phim nào có doanh thu cao nhất
csvsort -c "revenue" -r tmdb-movies.csv | head -n 2 > max-revenue.csv

# Tìm ra phim nào có doanh thu thấp nhất
csvsort -c "revenue" tmdb-movies.csv | head -n 2 > min-revenue.csv

# Tính tổng doanh thu tất cả các bộ phim
csvstat --sum "revenue" tmdb-movies.csv

# Xử lý dữ liệu null
sed 's/,,/,0,/g; s/,$/,0/' tmdb-movies.csv > tmdb-movies-notnull.csv

# Tính lợi nhuận và thêm vào cuối 
#awk -v FPAT='([^,]+)|(\"[^\"]+\")' '
#BEGIN { OFS="," }
#NR==1 { gsub(/\n/," ",$0) ; print $0",profit" }
#NR>1 {
#    # Loại bỏ dấu ngoặc kép từ các cột để tránh lỗi
#    gsub(/"/, "", $4);  # budget
#    gsub(/"/, "", $5);  # revenue
#
#    # Xử lý giá trị rỗng
#    if ($4 == "") $4 = 0;
#    if ($5 == "") $5 = 0;
#
#    # Tính lợi nhuận
#    profit = $5 - $4;
#
#    # In ra dòng dữ liệu và lợi nhuận, đảm bảo không có ký tự xuống dòng
#    gsub(/\n/, " ", $0);
#    print $0","profit
#}' tmdb-movies-notnull.csv > tmdb-movies-profit.csv

# Tính toán Profit
awk -v RS='\r?\n' -F, 'NR==1 {print $0",profit"; next} {profit = $5 - $4; print $0","profit}' tmdb-movies-notnull.csv > tmdb-movies-with-profit.csv

# Top 10 bộ phim đem về lợi nhuận cao nhất
csvsort -c profit -r tmdb-movies-with-profit.csv | head -n 11 > top-10-profit.csv

# Đạo diễn có nhiều phim nhất
csvcut -c director tmdb-movies-notnull.csv | sed 's/|/\n/g' | awk 'NF > 0' > directors-list.txt # Cột đạo diễn có chứa nhiều đạo diễn nên tách các đạo diễn thành từng dòng và lưu vào một danh sách các đạo diễn
grep -v '^0$' director-list.txt > cleaned-director-list.txt # Loại dòng dữ liệu chỉ chứa số 0
sort cleaned-director-list.txt | uniq -c | sort -nr | head -n 1 > top-director.csv # Đếm số lần các đạo diễn xuất hiện sau đó sắp xếp và lấy đạo diễn xuất hiện nhiều nhất

# Diễn viên có nhiều phim nhất (tương tự cách tìm đạo diễn nhiều phim nhất)
csvcut -c cast tmdb-movies-notnull.csv | sed 's/|/\n/g' | awk 'NF > 0' > cast-list.txt
grep -v '^0$' cast-list.txt > cleaned-cast-list.txt
sort cleaned-cast-list.txt | uniq -c | sort -nr | head -n 1 > top-cast.csv

# Thống kê số lượng phim theo thế loại
csvcut -c genres tmdb-movies-notnull.csv | sed 's/|/\n/g' | awk 'NF > 0' > genres-list.txt
grep -v '^0$' genres-list.txt > cleaned-genres-list.txt
sort cleaned-cast-list.txt | uniq -c | sort -nr > count-movies-by-genres.csv
