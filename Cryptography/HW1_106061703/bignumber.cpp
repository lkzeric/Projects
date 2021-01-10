#include <iostream> 
#include <cstring> 
#include <algorithm> 

using namespace std;

class BidNumber
{
    public:
	
        static const int size = 100;
        bool sign;
        BidNumber();
        BidNumber(const char *n);
        BidNumber invert() const;
        friend ostream& operator << (ostream& os, BidNumber t);
        friend bool operator > (const BidNumber& tl, const BidNumber& tr);    
        friend bool operator < (const BidNumber& tl, const BidNumber& tr);    
        friend BidNumber operator + (const BidNumber& tl, const BidNumber& tr);
		friend BidNumber operator + (const BidNumber& tl, const int& tr);
        friend BidNumber operator - (const BidNumber& tl, const BidNumber& tr);
        friend BidNumber operator * (const BidNumber& tl, const BidNumber& tr);        
        friend BidNumber operator / (BidNumber& tl, const BidNumber& tr); 
		friend BidNumber operator % (BidNumber& tl, const BidNumber& tr);
		
    private:
        void initialize();    
        int num[size];
        int len;
	
};
void BidNumber::initialize()
{
    sign = true;
    len = 1;
    memset(num, 0, sizeof(num));    //initialize the bignumber
}


BidNumber::BidNumber()
{
    initialize();
}

BidNumber::BidNumber(const char *n)  //input
{
    initialize();
	
   

    int check = 0;
   
    len = strlen(n);
   
    for(int i=check; i<len ;i++)
    {
        if(n[i] == '0')
            check++;
        else
            break;
		
		
    }
    for(int i=len-1, j=0; i>=check; i--, j++)
    {   
		
        switch(n[i]){         // transform char to int
		case '0':
		   num[j] = 0; 		   
           break;
		case '1':
		   num[j] = 1; 		   
           break;
		case '2':
		   num[j] = 2; 		   
           break;
		case '3':
		   num[j] = 3; 		   
           break;
		case '4':
		   num[j] =4; 		   
           break;
		case '5':
		   num[j] = 5; 		   
           break;
		case '6':
		   num[j] = 6; 		   
           break;
		case '7':
		   num[j] = 7; 		   
           break;
		case '8':
		   num[j] = 8; 		   
           break;
		case '9':
		   num[j] = 9; 		   
           break;
		case 'a':            //define a~f in the int
		   num[j] = 10; 		   
           break;
		case 'b':
		   num[j] = 11; 		   
           break;
		case 'c':
		   num[j] = 12; 		   
           break;
		case 'd':
		   num[j] = 13; 		   
           break;
		case 'e':
		   num[j] = 14; 		   
           break;
		case 'f':
		   num[j] = 15; 		   
           break;
		
		}
	}
    len -= check;
    if(len == 0)    // if empty 
    {
        num[0] = 0;
        len = 1;    
    }
}
BidNumber BidNumber::invert() const    // invert the sign of  the bidnumber    
{
    BidNumber tmp(*this);
    tmp.sign = !tmp.sign;
    return tmp;    
}


ostream& operator << (ostream& os, BidNumber t)  //output
{
    char tmp[BidNumber::size];
    int len = 0;
	
	
	if(t.sign == false)
    {
        tmp[0] = '-';
        len++;
    }
    
    for(int i=t.len-1; i>=0; i--)
    {
		
		
		
        switch(t.num[i]){          // transform int to char 
		case 0:	
		  tmp[len] = '0'; 
		  break;
		case 1:
		  tmp[len] = '1'; 		  
           break;
		case 2:
		   tmp[len] = '2'; 		   
           break;
		case 3:
		   tmp[len]= '3'; 		   
           break;
		case 4:
		  tmp[len] = '4'; 		   
           break;
		case 5:
		   tmp[len] ='5'; 	   
           break;
		case 6:
		   tmp[len] ='6';  		   
           break;
		case 7:
		  tmp[len] = '7'; 		   
           break;
		case 8:
		   tmp[len] = '8'; 		   
           break;
		case 9:
		    tmp[len] ='9'; 		   
           break;
		case 10:
		   tmp[len] = 'a'; 		   
           break;
		case 11:
		  tmp[len] = 'b'; 		   
           break;
		case 12:
		  tmp[len] ='c'; 		   
           break;
		case 13:
		 tmp[len] = 'd'; 		   
           break;
		case 14:
		  tmp[len] = 'e'; 		   
           break;
		case 15:
		  tmp[len] = 'f'; 		   
           break;
		}
        len++;
		
    } 
    tmp[len] = '\0';
    os << tmp;
    return os;
}


bool operator > (const BidNumber& tl, const BidNumber& tr)
{
    if(tl.sign == true && tr.sign == true)    //compare the sign of the bignumber
    {
        if(tl.len > tr.len) return true;
        else if(tl.len < tr.len) return false;
        else
        {
            for(int i=tl.len-1; i>=0; i--)
            {
                if(tl.num[i] > tr.num[i]) return true;
                else if(tl.num[i] < tr.num[i]) return false;
                else continue;    
            }
            return false;
        }    
    }
    else if(tl.sign == true && tr.sign == false)
        return true;
    else if(tl.sign == false && tr.sign == true)
        return false;
    else if(tl.sign == false && tr.sign == false)
    {
        return tr.invert() > tl.invert();    
    }
}
bool operator < (const BidNumber& tl, const BidNumber& tr)
{
    return (tr > tl);    
}

BidNumber operator + (const BidNumber& tl, const BidNumber& tr) //bignumber + bignumber
{
    BidNumber ans;
    
    ans.len = (tl.len > tr.len) ? tl.len : tr.len;
    for(int i=0; i<ans.len; i++)
    {
        ans.num[i] += tl.num[i] + tr.num[i];    
        if(ans.num[i] >= 16)            // check the carry number
        {
            ans.num[i + 1] += (ans.num[i] / 16);
            ans.num[i] %= 16;    
        }
    }
    if(ans.num[ans.len] != 0 )
    {
        ans.len++;    
    }
    return ans;
}

BidNumber operator +(const BidNumber& tl, const int& tr) //bignumber + integer 
{
    BidNumber ans;

    for(int i=0; i<tl.len; i++)
    {
        ans.num[i] += tl.num[i] + tr;    
        if(ans.num[i] >= 16)            // check the carry number
        {
            ans.num[i + 1] += (ans.num[i] / 16);
            ans.num[i] %= 16;    
        }
    }
    if(ans.num[ans.len] != 0 )
    {
        ans.len++;    
    }
    return ans;
}


BidNumber operator - (const BidNumber& tl, const BidNumber& tr)
{
    BidNumber ans;
        if(tl < tr)
        {
            ans = tr - tl;
            ans.sign = false; //change the sign at the end of the calculation
            return ans;
        }    
        else
        {
			ans.len = (tl.len > tr.len) ? tl.len : tr.len;
			int i,borrow;
			for(borrow=i=0 ; i<ans.len ; i++)
			{
				ans.num[i]=tl.num[i]-tr.num[i]-borrow;
				if(ans.num[i]<0)
				{
					ans.num[i]+=16;
					borrow=1;
				}
				else 
				{
					borrow=0;
				}		
				
			}
		}	
            for(int i=tl.len-1; i>=0; i--, ans.len--)
            {
                if(ans.num[i] != 0)    
                    break;
            }
            if(ans.len == 0)
            {
                ans.len = 1;
                ans.num[0] = 0;
            }
			
            return ans;          
}


BidNumber operator * (const BidNumber& tl, const BidNumber& tr)
{
    BidNumber ans;
    
    ans.len = tl.len + tr.len;
	
	int i,j,carry;
	
	for(int i=0 ; i<tl.len ; i++)  //store the value in char without carring 
	{
		if (tl.num[i]==0)
			continue;
		for(int j=0 ; j<tr.len ; j++)
		{
			ans.num[i+j]+= (tl.num[i]*tr.num[j]);
		}
	}
	for(int i=0 ; i<ans.len ; i++)  //check the carry number
	{
		if(ans.num[i] >= 16 )     
		{
			ans.num[i+1] += (ans.num[i]/16);
			ans.num[i] %= 16;
		}
	}
	
    if(ans.num[ans.len - 1] == 0)
    {
        ans.len--;    
    }
    return ans;
}

BidNumber operator / ( BidNumber& tl, const BidNumber& tr)
{

	BidNumber t;
    
	
	for(int i=0 ; i<10000 ;i++) //calculate the time of substraction
	{
		tl=tl-tr;
		t=(t+1);
		if(tl<tr)
		{
			break;
		}	
	}

	return t;
}

BidNumber operator % ( BidNumber& tl, const BidNumber& tr)
{
	BidNumber ans;       
	ans = tr * (tl/tr)-tl;   
	return ans;
	
	
}

int main()
{
    char str1[100], str2[100];
    while( cin >> str1 >> str2 )
    {
        BidNumber a(str1);
        BidNumber b(str2);
		
        cout << "+ :" << a + b << endl;
        cout << "- :" << a - b << endl;
        cout << "* :" << a * b << endl;
        cout << "/ :" << a / b << endl;
		cout << "% :" << a % b << endl;
    }
    return 0;
}




